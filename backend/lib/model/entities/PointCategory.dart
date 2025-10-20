class PointCategory {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  PointCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory PointCategory.fromJson(Map<String, dynamic> json) {
    return PointCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] as DateTime 
          : DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
