import '../../entities/Product.dart';

class ProductResponseDto {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int partnerId;
  final int pointId;
  final double weight;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? quantity;

  ProductResponseDto({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.partnerId,
    required this.pointId,
    required this.weight,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.quantity,
  });

  factory ProductResponseDto.fromEntity(Product product) {
    return ProductResponseDto(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
      partnerId: product.partnerId,
      pointId: product.pointId,
      weight: product.weight,
      isAvailable: product.isAvailable,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      quantity: product.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'partner_id': partnerId,
      'point_id': pointId,
      'weight': weight,
      'is_available': isAvailable,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (quantity != null) 'quantity': quantity,
    };
  }
}
