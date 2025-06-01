import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';

class AuthUtils {
  static String get _jwtSecret {
    final secret = Platform.environment['JWT_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_SECRET не установлен в переменных окружения');
    }
    return secret;
  }

  static String get _refreshSecret {
    final secret = Platform.environment['JWT_REFRESH_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_REFRESH_SECRET не установлен в переменных окружения');
    }
    return secret;
  }

  static const int _tokenExpirationInMinutes = 15;
  static const int _refreshTokenExpirationInDays = 7;

  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }

  static Map<String, String> generateTokens(int userId, String role) {
    final accessToken = _generateAccessToken(userId, role);
    final refreshToken = _generateRefreshToken(userId);

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  static String _generateAccessToken(int userId, String role) {
    final payload = {
      'id': userId,
      'role': role,
      'type': 'access',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(minutes: _tokenExpirationInMinutes)).millisecondsSinceEpoch ~/ 1000,
      'jti': _generateJTI(),
    };
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    return _encodeJWT(header, payload, _jwtSecret);
  }

  static String _generateRefreshToken(int userId) {
    final payload = {
      'id': userId,
      'type': 'refresh',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(days: _refreshTokenExpirationInDays)).millisecondsSinceEpoch ~/ 1000,
      'jti': _generateJTI(),
    };
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    return _encodeJWT(header, payload, _refreshSecret);
  }

  static String _generateJTI() {
    final random = DateTime.now().millisecondsSinceEpoch.toString() + 
                  (1000 + DateTime.now().microsecond).toString();
    return sha256.convert(utf8.encode(random)).toString();
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
      final payload = JwtDecoder.decode(token);
      
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
} 
