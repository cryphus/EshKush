import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/order.dart';

class OrderApiService {
  final Dio _dio = ApiClient().dio;

  /// Все заказы (admin)
  Future<List<Order>> getAllOrders({String? status}) async {
    try {
      final response = await _dio.get('/orders/', queryParameters: {
        if (status != null) 'status': status,
      });
      return (response.data as List).map((j) => Order.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Заказы конкретного пользователя
  Future<List<Order>> getUserOrders(int userId) async {
    try {
      final response = await _dio.get('/orders/user/$userId');
      return (response.data as List).map((j) => Order.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Получить заказ по ID
  Future<Order> getOrderById(int id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Создать заказ
  Future<Order> createOrder({
    required int userId,
    required int pointId,
    required List<int> productsId,
    required double totalPrice,
  }) async {
    try {
      final response = await _dio.post('/orders/', data: {
        'user_id': userId,
        'point_id': pointId,
        'products_id': productsId,
        'total_price': totalPrice,
      });
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Обновить статус заказа
  Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _dio.put('/orders/$orderId/status', data: {
        'status': status,
      });
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Удалить заказ
  Future<void> deleteOrder(int orderId) async {
    try {
      await _dio.delete('/orders/$orderId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Возврат средств по заказу. Бэк делегирует YooKassa + маркирует
  /// заказ как cancelled. В ответ возвращает обновлённую транзакцию.
  Future<void> refundOrder(int orderId, {String? reason}) async {
    try {
      await _dio.post('/orders/$orderId/refund', data: {
        if (reason != null) 'description': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
