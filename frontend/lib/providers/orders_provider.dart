import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/order_api_service.dart';
import '../models/order.dart';

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({this.orders = const [], this.isLoading = false, this.error});

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderApiService _api;

  OrdersNotifier({OrderApiService? api})
      : _api = api ?? OrderApiService(),
        super(const OrdersState());

  Future<void> loadUserOrders(int userId) async {
    if (userId <= 0) {
      state = const OrdersState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _api.getUserOrders(userId);
      state = OrdersState(orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setOrders(List<Order> orders) {
    state = OrdersState(orders: orders);
  }

  void addOrder(Order order) {
    state = state.copyWith(orders: [...state.orders, order]);
  }

  void updateOrder(Order updated) {
    state = state.copyWith(
      orders: state.orders.map((o) => o.id == updated.id ? updated : o).toList(),
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const OrdersState();
  }

  /// Отменяет заказ через возврат у платёжного шлюза.
  /// После успеха локально переводит заказ в `cancelled`.
  /// Возвращает true при успехе и false при ошибке (текст в state.error).
  Future<bool> cancelOrder(int orderId, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.refundOrder(orderId, reason: reason);
      final updated = state.orders.map((o) {
        if (o.id != orderId) return o;
        return Order(
          id: o.id,
          productsId: o.productsId,
          userId: o.userId,
          pointId: o.pointId,
          date: o.date,
          status: OrderStatus.cancelled,
          totalPrice: o.totalPrice,
          createdAt: o.createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList();
      state = OrdersState(orders: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  List<Order> get activeOrders =>
      state.orders.where((o) => o.isPending || o.status == OrderStatus.processing).toList();
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier();
});
