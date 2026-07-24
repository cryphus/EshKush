import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/point.dart';

class PointApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить все точки. [cityId] — фильтр по городу (бэкенд: ?city_id=N).
  Future<List<Point>> getAllPoints({int? cityId}) async {
    try {
      final response = await _dio.get('/points/', queryParameters: {
        'limit': 100,
        if (cityId != null) 'city_id': cityId,
      });
      final data = response.data;
      final list = data is Map ? (data['data'] as List? ?? []) : (data as List);
      return list.map((j) => Point.fromJson(j as Map<String, dynamic>)).toList();
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
