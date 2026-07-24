class Point {
  final int id;
  final String name;
  final String address;
  final double rating;
  final int cityId;
  final Map<String, dynamic> products;
  final String openingHours;
  final String closingHours;
  final int partnerId;
  final double longitude;
  final double latitude;
  final Map<String, dynamic> tags;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  /// Расстояние до пользователя в метрах.
  /// Заполняется только для ответа /points/nearby.
  final double? distanceM;

  const Point({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.cityId,
    required this.products,
    required this.openingHours,
    required this.closingHours,
    required this.partnerId,
    required this.longitude,
    required this.latitude,
    required this.tags,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.distanceM,
  });

  factory Point.fromJson(Map<String, dynamic> json) => Point(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        cityId: json['city_id'] as int? ?? 0,
        products: json['products'] as Map<String, dynamic>? ?? {},
        openingHours: json['opening_hours'] as String? ?? '',
        closingHours: json['closing_hours'] as String? ?? '',
        partnerId: json['partner_id'] as int? ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        tags: json['tags'] as Map<String, dynamic>? ?? {},
        imageUrl: json['image_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        distanceM: (json['distance_m'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'rating': rating,
        'city_id': cityId,
        'products': products,
        'opening_hours': openingHours,
        'closing_hours': closingHours,
        'partner_id': partnerId,
        'longitude': longitude,
        'latitude': latitude,
        'tags': tags,
        'image_url': imageUrl,
        if (distanceM != null) 'distance_m': distanceM,
      };

  String get workingHours => '$openingHours - $closingHours';

  /// Фото заведения: реальное (из БД), либо, пока его нет, стабильная
  /// (детерминированная по id) заглушка.
  String get photoUrl => imageUrl ?? 'https://picsum.photos/seed/venue-$id/800/400';

  /// Человекочитаемое расстояние, например "450 м" или "2.3 км".
  /// Возвращает null если distanceM не задан.
  String? get distanceLabel {
    final d = distanceM;
    if (d == null) return null;
    if (d < 1000) return '${d.round()} м';
    return '${(d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)} км';
  }
}
