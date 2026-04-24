
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

  Product({
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

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Преобразуем числовые поля
      if (json['id'] == null) throw ArgumentError('Product.fromJson: поле id обязательно');
      final id = json['id'] is String ? int.parse(json['id']) : json['id'] as int;

      if (json['partner_id'] == null) throw ArgumentError('Product.fromJson: поле partner_id обязательно');
      final partnerId = json['partner_id'] is String ? int.parse(json['partner_id']) : json['partner_id'] as int;

      if (json['point_id'] == null) throw ArgumentError('Product.fromJson: поле point_id обязательно');
      final pointId = json['point_id'] is String ? int.parse(json['point_id']) : json['point_id'] as int;

      // Преобразуем строковые поля
      final name = json['name']?.toString() ?? '';
      final description = json['description']?.toString() ?? '';
      final imageUrl = json['image_url']?.toString();

      // Преобразуем числовые поля с плавающей точкой
      final price = json['price'] == null ? 0.0 :
          (json['price'] is String ? double.parse(json['price']) : (json['price'] as num).toDouble());
          
      final weight = json['weight'] == null ? 0.0 :
          (json['weight'] is String ? double.parse(json['weight']) : (json['weight'] as num).toDouble());

      // Преобразуем булевы поля
      final isAvailable = json['is_available'] as bool? ?? true;
      final isActive = json['is_active'] as bool? ?? true;

      // Преобразуем даты
      final createdAt = json['created_at'] == null ? DateTime.now() :
          (json['created_at'] is DateTime 
              ? json['created_at'] as DateTime 
              : DateTime.parse(json['created_at'] as String));
              
      final updatedAt = json['updated_at'] == null ? null :
          (json['updated_at'] is DateTime 
              ? json['updated_at'] as DateTime 
              : DateTime.parse(json['updated_at'] as String));

      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        partnerId: partnerId,
        pointId: pointId,
        weight: weight,
        isAvailable: isAvailable,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      return product;
    } catch (e) {
      rethrow;
    }
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
      'updated_at': updatedAt?.toIso8601String(),
      'quantity': quantity,
    };
  }
} 
