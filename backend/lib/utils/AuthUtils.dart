import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

class AuthUtils {
  static String? _jwtSecretCached;
  static String? _refreshSecretCached;

  static String get _jwtSecret =>
      _jwtSecretCached ??= _readRequired('JWT_SECRET');

  static String get _refreshSecret =>
      _refreshSecretCached ??= _readRequired('JWT_REFRESH_SECRET');

  static String _readRequired(String key) {
    final v = Platform.environment[key];
    if (v == null || v.isEmpty) throw Exception('$key не установлен в переменных окружения');
    return v;
  }

  static const int _tokenExpirationInMinutes = 15;
  static const int _refreshTokenExpirationInDays = 7;
  static const int _defaultClockSkewSeconds = 60;

  static int get _clockSkewSeconds {
    final raw = Platform.environment['JWT_CLOCK_SKEW_SEC'];
    final parsed = raw == null ? null : int.tryParse(raw);
    return (parsed != null && parsed >= 0) ? parsed : _defaultClockSkewSeconds;
  }

  static String? get _jwtIssuer {
    final iss = Platform.environment['JWT_ISSUER'];
    return (iss == null || iss.trim().isEmpty) ? null : iss.trim();
  }

  static String? get _jwtAudience {
    final aud = Platform.environment['JWT_AUDIENCE'];
    return (aud == null || aud.trim().isEmpty) ? null : aud.trim();
  }

  static const int _defaultBcryptLogRounds = 12;

  static int get _bcryptLogRounds {
    final raw = Platform.environment['BCRYPT_LOG_ROUNDS'];
    final parsed = raw == null ? null : int.tryParse(raw);
    if (parsed != null && parsed >= 4 && parsed <= 14) return parsed;
    return _defaultBcryptLogRounds;
  }

  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _bcryptLogRounds));
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }

  static Map<String, String> generateTokens(int userId, String role) {
    final bundle = generateTokenBundle(userId, role);
    return {
      'access_token': bundle['access_token'] as String,
      'refresh_token': bundle['refresh_token'] as String,
    };
  }

  static Map<String, dynamic> generateTokenBundle(int userId, String role) {
    final now = DateTime.now();
    final refreshJti = _generateJTI();
    final refreshExp = now.add(Duration(days: _refreshTokenExpirationInDays));
    final accessToken = _generateAccessToken(userId, role, refreshJti: refreshJti, issuedAt: now);
    final refreshToken = _generateRefreshToken(userId, refreshJti: refreshJti, issuedAt: now);

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'refresh_jti': refreshJti,
      'refresh_expires_at': refreshExp,
    };
  }

  static String _generateAccessToken(int userId, String role, {required String refreshJti, required DateTime issuedAt}) {
    final iat = issuedAt.millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'id': userId,
      'role': role,
      'type': 'access',
      'iat': iat,
      'nbf': iat,
      'exp': issuedAt.add(Duration(minutes: _tokenExpirationInMinutes)).millisecondsSinceEpoch ~/ 1000,
      'jti': _generateJTI(),
      'rtj': refreshJti,
    };

    final iss = _jwtIssuer;
    final aud = _jwtAudience;
    if (iss != null) payload['iss'] = iss;
    if (aud != null) payload['aud'] = aud;
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    return _encodeJWT(header, payload, _jwtSecret);
  }

  static String _generateRefreshToken(int userId, {required String refreshJti, required DateTime issuedAt}) {
    final iat = issuedAt.millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'id': userId,
      'type': 'refresh',
      'iat': iat,
      'nbf': iat,
      'exp': issuedAt.add(Duration(days: _refreshTokenExpirationInDays)).millisecondsSinceEpoch ~/ 1000,
      'jti': refreshJti,
    };

    final iss = _jwtIssuer;
    final aud = _jwtAudience;
    if (iss != null) payload['iss'] = iss;
    if (aud != null) payload['aud'] = aud;
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    return _encodeJWT(header, payload, _refreshSecret);
  }

  static final _uuid = Uuid();

  static String _generateJTI() {
    // v4 использует dart:math Random.secure() — криптографически стойкий
    return _uuid.v4();
  }

  static String _encodeJWT(Map<String, dynamic> header, Map<String, dynamic> payload, String secret) {
    final headerBase64 = base64Url.encode(utf8.encode(json.encode(header)));
    final payloadBase64 = base64Url.encode(utf8.encode(json.encode(payload)));
    
    final signature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode('$headerBase64.$payloadBase64'))
        .bytes;
    final signatureBase64 = base64Url.encode(signature);
    
    return '$headerBase64.$payloadBase64.$signatureBase64';
  }

  static Map<String, dynamic> verifyToken(String token, {bool isRefreshToken = false}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Неверный формат токена');
      }

      final header = _decodeSegment(parts[0]);
      final payload = _decodeSegment(parts[1]);

      final alg = header['alg']?.toString();
      if (alg != 'HS256') {
        throw Exception('Неподдерживаемый алгоритм подписи');
      }
      final typ = header['typ']?.toString();
      if (typ != null && typ != 'JWT') {
        throw Exception('Неверный тип токена');
      }

      final secret = isRefreshToken ? _refreshSecret : _jwtSecret;
      final expectedSignature = _sign(parts[0], parts[1], secret);
      if (!_constantTimeEqual(parts[2], expectedSignature)) {
        throw Exception('Неверная подпись токена');
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final skew = _clockSkewSeconds;

      final exp = _readInt(payload['exp']);
      if (exp == null) {
        throw Exception('Отсутствует exp в токене');
      }
      if (now - skew >= exp) {
        throw Exception('Токен истёк');
      }

      final nbf = _readInt(payload['nbf']);
      if (nbf != null && now + skew < nbf) {
        throw Exception('Токен ещё не активен (nbf)');
      }

      final iat = _readInt(payload['iat']);
      if (iat != null && now + skew < iat) {
        throw Exception('Недопустимое время выпуска (iat)');
      }

      final expectedIss = _jwtIssuer;
      if (expectedIss != null && payload['iss']?.toString() != expectedIss) {
        throw Exception('Неверный issuer (iss)');
      }

      final expectedAud = _jwtAudience;
      if (expectedAud != null && !_audienceMatches(payload['aud'], expectedAud)) {
        throw Exception('Неверный audience (aud)');
      }
      
      if (isRefreshToken && payload['type'] != 'refresh') {
        throw Exception('Неверный тип токена');
      }
      
      if (!isRefreshToken && payload['type'] != 'access') {
        throw Exception('Неверный тип токена');
      }

      if (payload['jti'] == null) {
        throw Exception('Отсутствует JTI в токене');
      }

      return payload;
    } catch (e) {
      throw Exception('Недействительный токен: $e');
    }
  }

  static bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  static String hashRefreshJti(String jti) {
    final mac = Hmac(sha256, utf8.encode(_refreshSecret));
    return mac.convert(utf8.encode(jti)).toString();
  }

  static Map<String, dynamic> _decodeSegment(String segment) {
    final normalized = base64Url.normalize(segment);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  static String _sign(String header, String payload, String secret) {
    final signature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode('$header.$payload'))
        .bytes;
    return base64Url.encode(signature);
  }

  static bool _constantTimeEqual(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool _audienceMatches(dynamic audClaim, String expected) {
    if (audClaim == null) return false;
    if (audClaim is String) return audClaim == expected;
    if (audClaim is List) {
      return audClaim.map((e) => e.toString()).contains(expected);
    }
    return false;
  }
} 
