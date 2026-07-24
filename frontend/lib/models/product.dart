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
  final double? originalPrice;
  final List<String> tags;
  final String? pickupStart;
  final String? pickupEnd;
  final int itemsCount;

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
    this.originalPrice,
    this.tags = const [],
    this.pickupStart,
    this.pickupEnd,
    this.itemsCount = 1,
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
        originalPrice: (json['original_price'] as num?)?.toDouble(),
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pickupStart: json['pickup_start'] as String?,
        pickupEnd: json['pickup_end'] as String?,
        itemsCount: (json['items_count'] as num?)?.toInt() ?? 1,
      );

  /// Товар можно купить/добавить в корзину, только если он доступен и
  /// остаток на складе не исчерпан (null остатка считаем "не отслеживается").
  bool get isPurchasable => isAvailable && (quantity == null || quantity! > 0);

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  String? get pickupWindowLabel =>
      (pickupStart != null && pickupEnd != null) ? '$pickupStart - $pickupEnd' : null;

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
        if (originalPrice != null) 'original_price': originalPrice,
        'tags': tags,
        if (pickupStart != null) 'pickup_start': pickupStart,
        if (pickupEnd != null) 'pickup_end': pickupEnd,
        'items_count': itemsCount,
      };
}
