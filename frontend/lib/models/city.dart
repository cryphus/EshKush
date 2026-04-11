class City {
  final int id;
  final String name;
  final DateTime? createdAt;

  const City({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
