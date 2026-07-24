import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/cart_api_service.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

class CartState {
  final List<CartItem> items;
  final bool isCheckingOut;
  final String? error;

  const CartState({
    this.items = const [],
    this.isCheckingOut = false,
    this.error,
  });

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    bool? isCheckingOut,
    String? error,
    bool clearError = false,
  }) =>
      CartState(
        items: items ?? this.items,
        isCheckingOut: isCheckingOut ?? this.isCheckingOut,
        error: clearError ? null : (error ?? this.error),
      );
}

class CartNotifier extends StateNotifier<CartState> {
  final CartApiService _api;

  CartNotifier({CartApiService? api})
      : _api = api ?? CartApiService(),
        super(const CartState());

  void addItem(Product product, int pointId, String pointName) {
    final stock = product.quantity;
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final current = state.items[existingIndex].quantity;
      if (stock != null && current >= stock) {
        state = state.copyWith(error: 'Больше нельзя добавить: осталось $stock шт.');
        return;
      }
      final updated = List<CartItem>.from(state.items);
      updated[existingIndex].quantity++;
      state = state.copyWith(items: updated, clearError: true);
    } else {
      if (stock != null && stock <= 0) {
        state = state.copyWith(error: 'Товар закончился');
        return;
      }
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, pointId: pointId, pointName: pointName)],
        clearError: true,
      );
    }
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = List<CartItem>.from(state.items);
    final index = updated.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final stock = updated[index].product.quantity;
      if (stock != null && quantity > stock) {
        state = state.copyWith(error: 'Больше нельзя добавить: осталось $stock шт.');
        return;
      }
      updated[index].quantity = quantity;
      state = state.copyWith(items: updated, clearError: true);
    }
  }

  void clear() {
    state = const CartState();
  }

  /// Оформляет заказ. Возвращает список созданных Order
  /// или null, если возникла ошибка (она будет в state.error).
  Future<List<Order>?> checkout({required int userId}) async {
    if (state.items.isEmpty) return null;
    state = state.copyWith(isCheckingOut: true, clearError: true);
    try {
      final orders = await _api.checkout(userId: userId, items: state.items);
      state = const CartState(); // очищаем корзину
      return orders;
    } catch (e) {
      state = state.copyWith(isCheckingOut: false, error: e.toString());
      return null;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
