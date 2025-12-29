import '../../entities/Point.dart';

class PointResponseDto {
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
  final DateTime createdAt;
  final DateTime? updatedAt;

  PointResponseDto({
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
    required this.createdAt,
    this.updatedAt,
  });

  factory PointResponseDto.fromEntity(Point point) {
    return PointResponseDto(
      id: point.id,
      name: point.name,
      address: point.address,
      rating: point.rating,
      cityId: point.cityId,
      products: point.products,
      openingHours: point.openingHours,
      closingHours: point.closingHours,
      partnerId: point.partnerId,
      longitude: point.longitude,
      latitude: point.latitude,
      tags: point.tags,
      createdAt: point.createdAt,
      updatedAt: point.updatedAt,
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
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
