import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/product.dart';

class ProductApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить все продукты
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _dio.get('/products/');
      return (response.data as List).map((j) => Product.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Получить продукт по ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Продукты по точке
  Future<List<Product>> getProductsByPoint(int pointId) async {
    try {
      final response = await _dio.get('/products/', queryParameters: {
        'point_id': pointId,
      });
      return (response.data as List).map((j) => Product.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
