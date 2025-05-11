import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io';

class AuthUtils {
  static final String _jwtSecret = Platform.environment['JWT_SECRET'] ?? 'your-secret-key';
  static final String _refreshSecret = Platform.environment['JWT_REFRESH_SECRET'] ?? 'your-refresh-secret-key';
  static const int _tokenExpirationInMinutes = 60;
  static const int _refreshTokenExpirationInDays = 7;

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
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
    };
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    return _encodeJWT(header, payload, _refreshSecret);
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
        throw Exception('Invalid token type');
      }
      
      if (!isRefreshToken && payload['type'] != 'access') {
        throw Exception('Invalid token type');
      }

      return payload;
    } catch (e) {
      throw Exception('Invalid token: $e');
    }
  }

  static bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }
} 
