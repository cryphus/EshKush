abstract class BaseMap {
  final DateTime createdAt;

  BaseMap({
    required this.createdAt,
  });

  void validateIds();

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseMap &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt;

  @override
  int get hashCode => createdAt.hashCode;

  @override
  String toString() => 'BaseMap(createdAt: $createdAt)';
} 