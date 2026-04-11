import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/point_api_service.dart';
import '../models/point.dart';

/// Параметры геопоиска — используются как ключ для family-провайдера.
class NearbyQuery {
  final double lat;
  final double lon;
  final double radiusM;
  final int limit;

  const NearbyQuery({
    required this.lat,
    required this.lon,
    this.radiusM = 5000,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyQuery &&
          lat == other.lat &&
          lon == other.lon &&
          radiusM == other.radiusM &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(lat, lon, radiusM, limit);
}

/// Family-провайдер: получает список ближайших точек для заданного запроса.
/// Использование:
/// ```dart
/// final nearby = ref.watch(nearbyPointsProvider(
///   NearbyQuery(lat: 55.75, lon: 37.62, radiusM: 3000),
/// ));
/// ```
final nearbyPointsProvider =
    FutureProvider.family<List<Point>, NearbyQuery>((ref, query) async {
  final api = PointApiService();
  return api.getNearby(
    lat: query.lat,
    lon: query.lon,
    radiusM: query.radiusM,
    limit: query.limit,
  );
});
