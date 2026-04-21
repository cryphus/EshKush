import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/point.dart';

class PointApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить все точки
  Future<List<Point>> getAllPoints() async {
    try {
      final response = await _dio.get('/points/');
      final data = response.data;
      final list = data is Map ? (data['data'] as List? ?? []) : (data as List);
      return list.map((j) => Point.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Поиск точек в радиусе [radiusM] метров вокруг (lat, lon),
  /// отсортированных по возрастанию расстояния. Возвращает Point с
  /// заполненным distanceM. Бэкенд: GET /points/nearby.
  Future<List<Point>> getNearby({
    required double lat,
    required double lon,
    double radiusM = 5000,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/points/nearby',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': radiusM,
          'limit': limit,
        },
      );
      return (response.data as List)
          .map((j) => Point.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Получить точку по ID
  Future<Point> getPointById(int id) async {
    try {
      final response = await _dio.get('/points/$id');
      return Point.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Создать точку (для партнёра)
  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/points/', data: data);
      return Point.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
