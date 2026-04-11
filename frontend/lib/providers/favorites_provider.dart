import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/favorite_api_service.dart';
import '../api/point_api_service.dart';
import '../models/point.dart';

class FavoritesState {
  final List<Point> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({this.favorites = const [], this.isLoading = false, this.error});

  FavoritesState copyWith({
    List<Point>? favorites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => FavoritesState(
        favorites: favorites ?? this.favorites,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoriteApiService _api;
  final PointApiService _pointsApi;

  FavoritesNotifier({
    FavoriteApiService? api,
    PointApiService? pointsApi,
  })  : _api = api ?? FavoriteApiService(),
        _pointsApi = pointsApi ?? PointApiService(),
        super(const FavoritesState());

  /// Загружает избранное и резолвит точки.
  /// Бэкенд возвращает список с `point_id` (или сразу объектами Point —
  /// зависит от реализации). Поддерживаем оба варианта.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final raw = await _api.getMyFavorites();
      final points = <Point>[];
      for (final entry in raw) {
        // Если бэк уже отдаёт вложенный объект point — используем его
        if (entry['point'] is Map<String, dynamic>) {
          points.add(Point.fromJson(entry['point'] as Map<String, dynamic>));
          continue;
        }
        // Если есть полные поля точки прямо в записи
        if (entry.containsKey('name') && entry.containsKey('address')) {
          points.add(Point.fromJson(entry));
          continue;
        }
        // Иначе достаём по id
        final pointId = entry['point_id'] as int?;
        if (pointId != null) {
          try {
            points.add(await _pointsApi.getPointById(pointId));
          } catch (_) {
            // пропускаем недоступные
          }
        }
      }
      state = FavoritesState(favorites: points);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> add(Point point) async {
    if (state.favorites.any((f) => f.id == point.id)) return;
    state = state.copyWith(favorites: [...state.favorites, point]);
    try {
      await _api.addFavorite(point.id);
    } catch (e) {
      // откат
      state = state.copyWith(
        favorites: state.favorites.where((f) => f.id != point.id).toList(),
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> remove(int pointId) async {
    final prev = state.favorites;
    state = state.copyWith(
      favorites: prev.where((f) => f.id != pointId).toList(),
    );
    try {
      await _api.removeFavorite(pointId);
    } catch (e) {
      state = state.copyWith(favorites: prev, error: e.toString());
      rethrow;
    }
  }

  void setFavorites(List<Point> favorites) {
    state = FavoritesState(favorites: favorites);
  }

  void addFavorite(Point point) {
    if (state.favorites.any((f) => f.id == point.id)) return;
    state = state.copyWith(favorites: [...state.favorites, point]);
  }

  void removeFavorite(int pointId) {
    state = state.copyWith(
      favorites: state.favorites.where((f) => f.id != pointId).toList(),
    );
  }

  bool isFavorite(int pointId) {
    return state.favorites.any((f) => f.id == pointId);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const FavoritesState();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});
