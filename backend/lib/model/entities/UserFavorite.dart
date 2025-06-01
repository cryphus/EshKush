import 'base/BaseMap.dart';

class UserFavorite extends BaseMap {
  final int userId;
  final int pointId;

  UserFavorite({
    required this.userId,
    required this.pointId,
    required DateTime createdAt,
  }) : super(createdAt: createdAt) {
    validateIds();
  }

  @override
  void validateIds() {
    if (userId <= 0) {
      throw ArgumentError('ID пользователя должен быть положительным числом');
    }
    if (pointId <= 0) {
      throw ArgumentError('ID точки должен быть положительным числом');
    }
  }

  factory UserFavorite.fromJson(Map<String, dynamic> json) {
    return UserFavorite(
      userId: json['user_id'] as int,
      pointId: json['point_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'point_id': pointId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserFavorite &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          pointId == other.pointId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => userId.hashCode ^ pointId.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'UserFavorite(userId: $userId, pointId: $pointId, createdAt: $createdAt)';
}