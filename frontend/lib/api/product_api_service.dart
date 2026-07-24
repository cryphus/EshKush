import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/product.dart';
import '../models/product_offer.dart';

class ProductApiService {
  final Dio _dio = ApiClient().dio;

  /// Бэкенд оборачивает списки в {data: [...], pagination: {...}};
  /// поддерживаем и «голый» список на всякий случай.
  List<Product> _parseList(dynamic data) {
    final list = data is Map ? (data['data'] as List? ?? []) : (data as List);
    return list.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Получить все продукты
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _dio.get('/products/', queryParameters: {
        'limit': 100,
      });
      return _parseList(response.data);
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
        'limit': 100,
      });
      return _parseList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Лента предложений для главного экрана: доступные сейчас товары
  /// вместе с данными их точки, одним запросом.
  Future<List<ProductOffer>> getFeed({int? cityId}) async {
    try {
      final response = await _dio.get('/products/feed', queryParameters: {
        'limit': 100,
        if (cityId != null) 'city_id': cityId,
      });
      final data = response.data;
      final list = data is Map ? (data['data'] as List? ?? []) : (data as List);
      return list
          .map((j) => ProductOffer.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
