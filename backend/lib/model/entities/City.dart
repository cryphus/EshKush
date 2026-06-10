class City {
  final int? id;
  final String name;
  final DateTime? createdAt;

  City({
    this.id,
    required this.name,
    this.createdAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }
    
    return City(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      name: json['name'].toString(),
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    
    if (id != null) {
      map['id'] = id;
    }
    
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'City(id: $id, name: $name, createdAt: $createdAt)';
}