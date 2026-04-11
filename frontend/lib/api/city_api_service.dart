import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/city.dart';

class CityApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить все города
  Future<List<City>> getAllCities() async {
    try {
      final response = await _dio.get('/cities/');
      return (response.data as List).map((j) => City.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
