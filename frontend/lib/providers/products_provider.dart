import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/product_api_service.dart';
import '../models/product.dart';

class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  const ProductsState({this.products = const [], this.isLoading = false, this.error});

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ProductsState(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductApiService _api;

  ProductsNotifier({ProductApiService? api})
      : _api = api ?? ProductApiService(),
        super(const ProductsState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _api.getAllProducts();
      state = ProductsState(products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadByPoint(int pointId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _api.getProductsByPoint(pointId);
      state = ProductsState(products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setProducts(List<Product> products) {
    state = ProductsState(products: products);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const ProductsState();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});
