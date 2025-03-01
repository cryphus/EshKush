import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';


class AuthUtils {
  static const String _jwtSecret = 'your-secret-key';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static String generateToken(int userId, String role) {
    final jwt = JWT({
      'id': userId,
      'role': role,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(_jwtSecret));
  }

  static Map<String, dynamic> verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload;
    } catch (e) {
      throw Exception('Invalid token');
    }
  }
} 