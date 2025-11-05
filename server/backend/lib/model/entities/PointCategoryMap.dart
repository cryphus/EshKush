import 'base/BaseMap.dart';

class PointCategoryMap extends BaseMap {
  final int pointId;
  final int categoryId;

  PointCategoryMap({
    required this.pointId,
    required this.categoryId,
    required DateTime createdAt,
  }) : super(createdAt: createdAt) {
    validateIds();
  }

  @override
  void validateIds() {
    if (pointId <= 0) {
      throw ArgumentError('ID точки должен быть положительным числом');
    }
    if (categoryId <= 0) {
      throw ArgumentError('ID категории должен быть положительным числом');
    }
  }

  factory PointCategoryMap.fromJson(Map<String, dynamic> json) {
    return PointCategoryMap(
      pointId: json['point_id'] as int,
      categoryId: json['category_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'point_id': pointId,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointCategoryMap &&
          runtimeType == other.runtimeType &&
          pointId == other.pointId &&
          categoryId == other.categoryId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => pointId.hashCode ^ categoryId.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'PointCategoryMap(pointId: $pointId, categoryId: $categoryId, createdAt: $createdAt)';
}