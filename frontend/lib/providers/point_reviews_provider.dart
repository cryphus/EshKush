import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/review_api_service.dart';
import '../models/review.dart';

class PointReviewsState {
  final List<Review> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const PointReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  PointReviewsState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) => PointReviewsState(
        reviews: reviews ?? this.reviews,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class PointReviewsNotifier extends StateNotifier<PointReviewsState> {
  final ReviewApiService _api;
  final int pointId;

  PointReviewsNotifier(this.pointId, {ReviewApiService? api})
      : _api = api ?? ReviewApiService(),
        super(const PointReviewsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reviews = await _api.getByPoint(pointId);
      state = state.copyWith(reviews: reviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Возвращает true при успехе — экран может закрыть форму.
  Future<bool> submit({required double rating, String? comment}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final review =
          await _api.create(pointId: pointId, rating: rating, comment: comment);
      state = state.copyWith(
        reviews: [review, ...state.reviews],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final pointReviewsProvider =
    StateNotifierProvider.family<PointReviewsNotifier, PointReviewsState, int>(
        (ref, pointId) {
  return PointReviewsNotifier(pointId);
});
