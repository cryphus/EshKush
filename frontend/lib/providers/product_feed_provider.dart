import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/product_api_service.dart';
import '../models/product_offer.dart';

class ProductFeedState {
  final List<ProductOffer> offers;
  final bool isLoading;
  final String? error;

  const ProductFeedState({this.offers = const [], this.isLoading = false, this.error});

  ProductFeedState copyWith({
    List<ProductOffer>? offers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ProductFeedState(
        offers: offers ?? this.offers,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProductFeedNotifier extends StateNotifier<ProductFeedState> {
  final ProductApiService _api;

  ProductFeedNotifier({ProductApiService? api})
      : _api = api ?? ProductApiService(),
        super(const ProductFeedState());

  Future<void> loadAll({int? cityId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final offers = await _api.getFeed(cityId: cityId);
      state = ProductFeedState(offers: offers);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final productFeedProvider =
    StateNotifierProvider<ProductFeedNotifier, ProductFeedState>((ref) {
  return ProductFeedNotifier();
});
