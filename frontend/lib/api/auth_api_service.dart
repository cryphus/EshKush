import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/user.dart';

class AuthApiService {
  final Dio _dio = ApiClient().dio;

  /// Вход по логину/паролю
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Регистрация нового пользователя
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String phone,
    required String role,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'username': username,
        'password': password,
        'number': phone,
        'role': role,
        if (displayName != null) 'displayName': displayName,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Google OAuth
  Future<Map<String, dynamic>> googleAuth(String idToken, String email) async {
    try {
      final response = await _dio.post('/auth/google', data: {
        'idToken': idToken,
        'email': email,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Обновление токена
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Проверка существования пользователя по номеру
  Future<Map<String, dynamic>> checkUser(String phoneNumber) async {
    try {
      final response = await _dio.post('/auth/check_user', data: {
        'phoneNumber': phoneNumber,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
