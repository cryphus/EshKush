import 'Point.dart';

/// Результат геопоиска: точка + расстояние до запрошенных координат в метрах.
class NearbyPoint {
  final Point point;
  final double distanceM;

  const NearbyPoint({
    required this.point,
    required this.distanceM,
  });
}
