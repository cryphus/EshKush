import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/point_api_service.dart';
import '../models/point.dart';

class PointsState {
  final List<Point> points;
  final bool isLoading;
  final String? error;

  const PointsState({this.points = const [], this.isLoading = false, this.error});

  PointsState copyWith({
    List<Point>? points,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => PointsState(
        points: points ?? this.points,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class PointsNotifier extends StateNotifier<PointsState> {
  final PointApiService _api;

  PointsNotifier({PointApiService? api})
      : _api = api ?? PointApiService(),
        super(const PointsState());

  Future<void> loadAll({int? cityId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final points = await _api.getAllPoints(cityId: cityId);
      state = PointsState(points: points);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setPoints(List<Point> points) {
    state = PointsState(points: points);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const PointsState();
  }
}

final pointsProvider = StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  return PointsNotifier();
});
