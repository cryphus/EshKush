class Product {
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

  const Product({
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

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['image_url'] as String?,
        partnerId: json['partner_id'] as int? ?? 0,
        pointId: json['point_id'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        isAvailable: json['is_available'] as bool? ?? true,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        quantity: json['quantity'] as int?,
      );

  Map<String, dynamic> toJson() => {
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
        if (quantity != null) 'quantity': quantity,
      };
}
