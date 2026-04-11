import '../models/cart_item.dart';
import '../models/order.dart';
import 'order_api_service.dart';

/// Корзина у нас клиентская — отдельных эндпоинтов на бэке нет.
/// Этот сервис отвечает только за оформление заказа: группирует
/// позиции по точкам и создаёт по одному `Order` на каждую точку.
class CartApiService {
  final OrderApiService _orders;

  CartApiService({OrderApiService? orderApiService})
      : _orders = orderApiService ?? OrderApiService();

  /// Оформляет корзину текущего пользователя.
  /// Возвращает список созданных заказов (по одному на каждую точку).
  Future<List<Order>> checkout({
    required int userId,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      throw StateError('Корзина пуста');
    }

    // Группируем позиции по точке
    final Map<int, List<CartItem>> byPoint = {};
    for (final item in items) {
      byPoint.putIfAbsent(item.pointId, () => []).add(item);
    }

    final created = <Order>[];
    for (final entry in byPoint.entries) {
      final pointId = entry.key;
      final pointItems = entry.value;

      final productsId = <int>[];
      double total = 0.0;
      for (final ci in pointItems) {
        for (var i = 0; i < ci.quantity; i++) {
          productsId.add(ci.product.id);
        }
        total += ci.totalPrice;
      }

      final order = await _orders.createOrder(
        userId: userId,
        pointId: pointId,
        productsId: productsId,
        totalPrice: total,
      );
      created.add(order);
    }

    return created;
  }
}
