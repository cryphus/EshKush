import 'package:dio/dio.dart';

import '../models/payment_transaction.dart';
import 'api_client.dart';

/// Работает с платёжным шлюзом (YooKassa) через наш backend.
/// Основной флоу: [createPayment] возвращает confirmation_url, который
/// открывается во внешнем браузере. Статус отслеживается через
/// [getTransactionsByOrder] (polling).
class PaymentApiService {
  final Dio _dio = ApiClient().dio;

  /// Инициировать платёж у YooKassa для указанного заказа.
  Future<PaymentInitResponse> createPayment({
    required int orderId,
    PaymentMethod paymentMethod = PaymentMethod.card,
    String? description,
    String? returnUrl,
  }) async {
    try {
      final response = await _dio.post('/payments/create', data: {
        'order_id': orderId,
        'payment_method': paymentMethod.name,
        if (description != null) 'description': description,
        if (returnUrl != null) 'return_url': returnUrl,
      });
      return PaymentInitResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Все транзакции по заказу (используется для polling статуса).
  Future<List<PaymentTransaction>> getTransactionsByOrder(int orderId) async {
    try {
      final response = await _dio.get(
        '/payment-transactions/order',
        queryParameters: {'order_id': orderId},
      );
      return (response.data as List)
          .map((j) =>
              PaymentTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Запросить возврат по заказу.
  Future<PaymentTransaction> refund({
    required int orderId,
    double? amount,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/payments/refund', data: {
        'order_id': orderId,
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
      });
      return PaymentTransaction.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
