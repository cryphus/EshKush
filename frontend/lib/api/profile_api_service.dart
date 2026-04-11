import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/profile.dart';

class ProfileApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить профиль текущего пользователя (по токену)
  Future<Profile> getMyProfile() async {
    try {
      final response = await _dio.get('/profiles/');
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Получить профиль по ID
  Future<Profile> getProfileById(int id) async {
    try {
      final response = await _dio.get('/profiles/$id');
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Создать профиль
  Future<Profile> createProfile({
    required String firstName,
    required String lastName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final response = await _dio.post('/profiles/', data: {
        'first_name': firstName,
        'last_name': lastName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
      });
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Обновить профиль
  Future<Profile> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/profiles/$id', data: data);
      return Profile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
