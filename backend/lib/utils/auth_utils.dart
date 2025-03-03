import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
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
    final jwt = JWT(
      {
        'id': userId,
        'role': role,
        'type': 'access',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(minutes: _tokenExpirationInMinutes)).millisecondsSinceEpoch ~/ 1000,
      },
      issuer: 'eshkush',
      subject: userId.toString(),
    );

    return jwt.sign(SecretKey(_jwtSecret));
  }

  static String _generateRefreshToken(int userId) {
    final jwt = JWT(
      {
        'id': userId,
        'type': 'refresh',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(days: _refreshTokenExpirationInDays)).millisecondsSinceEpoch ~/ 1000,
      },
      issuer: 'eshkush',
      subject: userId.toString(),
    );

    return jwt.sign(SecretKey(_refreshSecret));
  }

  static Map<String, dynamic> verifyToken(String token, {bool isRefreshToken = false}) {
    try {
      final jwt = JWT.verify(
        token,
        SecretKey(isRefreshToken ? _refreshSecret : _jwtSecret),
      );
      
      if (isRefreshToken && jwt.payload['type'] != 'refresh') {
        throw Exception('Invalid token type');
      }
      
      if (!isRefreshToken && jwt.payload['type'] != 'access') {
        throw Exception('Invalid token type');
      }

      return jwt.payload;
    } on JWTExpiredException {
      throw Exception('Token has expired');
    } on JWTException catch (e) {
      throw Exception('Invalid token: ${e.message}');
    }
  }

  static bool isTokenExpired(String token) {
    try {
      verifyToken(token);
      return false;
    } catch (e) {
      return true;
    }
  }
} 