import 'package:dio/dio.dart';
import 'api_client.dart';

class FavoriteApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить избранное текущего пользователя
  Future<List<Map<String, dynamic>>> getMyFavorites() async {
    try {
      final response = await _dio.get('/favorites/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Добавить в избранное
  Future<void> addFavorite(int pointId) async {
    try {
      await _dio.post('/favorites/', data: {
        'point_id': pointId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Удалить из избранного
  Future<void> removeFavorite(int pointId) async {
    try {
      await _dio.delete('/favorites/$pointId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Проверить, в избранном ли точка
  Future<bool> isFavorite(int pointId) async {
    try {
      final response = await _dio.get('/favorites/is-favorite/$pointId');
      return response.data['isFavorite'] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
