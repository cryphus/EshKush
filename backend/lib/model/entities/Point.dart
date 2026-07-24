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

  Point({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 0.0,
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
  }) {
    _validateTimeFormat(openingHours);
    _validateTimeFormat(closingHours);
  }

  void _validateTimeFormat(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!regex.hasMatch(time)) {
      throw ArgumentError('Invalid time format. Expected HH:mm');
    }
  }
  
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      cityId: int.parse(json['city_id'].toString()),
      products: json['products'] as Map<String, dynamic>,
      openingHours: json['opening_hours'] as String,
      closingHours: json['closing_hours'] as String,
      partnerId: int.parse(json['partner_id'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      latitude: double.parse(json['latitude'].toString()),
      tags: json['tags'] as Map<String, dynamic>,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] is DateTime ? json['created_at'] as DateTime : DateTime.parse(json['created_at'].toString()),
      updatedAt: json['updated_at'] != null ? (json['updated_at'] is DateTime ? json['updated_at'] as DateTime : DateTime.parse(json['updated_at'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          rating == other.rating &&
          cityId == other.cityId &&
          products == other.products &&
          openingHours == other.openingHours &&
          closingHours == other.closingHours &&
          partnerId == other.partnerId &&
          longitude == other.longitude &&
          latitude == other.latitude &&
          tags == other.tags &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      rating.hashCode ^
      cityId.hashCode ^
      products.hashCode ^
      openingHours.hashCode ^
      closingHours.hashCode ^
      partnerId.hashCode ^
      longitude.hashCode ^
      latitude.hashCode ^
      tags.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Point(id: $id, name: $name, address: $address, rating: $rating, '
      'cityId: $cityId, partnerId: $partnerId, longitude: $longitude, '
      'latitude: $latitude, createdAt: $createdAt, updatedAt: $updatedAt)';
} 
