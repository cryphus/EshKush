import '../../../utils/ValidationUtils.dart';

class CreateProductDto {
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int partnerId;
  final int pointId;
  final double weight;
  final bool isAvailable;
  final bool isActive;
  final int quantity;
  final double? originalPrice;
  final List<String> tags;
  final String? pickupStart;
  final String? pickupEnd;
  final int itemsCount;

  CreateProductDto({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.partnerId,
    required this.pointId,
    required this.weight,
    this.isAvailable = true,
    this.isActive = true,
    this.quantity = 20,
    this.originalPrice,
    this.tags = const [],
    this.pickupStart,
    this.pickupEnd,
    this.itemsCount = 1,
  });

  factory CreateProductDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty || !ValidationUtils.isValidName(name)) {
      errors.add('Некорректное название продукта');
    }

    final description = json['description']?.toString().trim() ?? '';
    if (description.isEmpty || description.length > 1000) {
      errors.add('Описание продукта обязательно и не должно превышать 1000 символов');
    }

    final price = json['price'] != null
        ? double.tryParse(json['price'].toString()) ?? 0.0
        : 0.0;
    if (price <= 0) {
      errors.add('Цена продукта должна быть положительным числом');
    }

    final pointId = json['point_id'] != null ? int.tryParse(json['point_id'].toString()) ?? 0 : 0;
    if (pointId <= 0) {
      errors.add('Некорректный ID точки');
    }

    final partnerId = json['partner_id'] != null ? int.tryParse(json['partner_id'].toString()) ?? 0 : 0;
    if (partnerId <= 0) {
      errors.add('Некорректный ID партнера');
    }

    final weight = json['weight'] != null
        ? double.tryParse(json['weight'].toString()) ?? 0.0
        : 0.0;
    if (weight < 0) {
      errors.add('Вес продукта должен быть неотрицательным числом');
    }

    final quantity =
        json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 20 : 20;
    if (quantity < 0) {
      errors.add('Количество товара не может быть отрицательным');
    }

    final originalPrice = json['original_price'] != null
        ? double.tryParse(json['original_price'].toString())
        : null;
    if (originalPrice != null && originalPrice < 0) {
      errors.add('Старая цена не может быть отрицательной');
    }

    final tags = json['tags'] == null
        ? <String>[]
        : (json['tags'] as List).map((e) => e.toString()).toList();

    final pickupStart = json['pickup_start']?.toString();
    final pickupEnd = json['pickup_end']?.toString();

    final itemsCount =
        json['items_count'] != null ? int.tryParse(json['items_count'].toString()) ?? 1 : 1;
    if (itemsCount < 1) {
      errors.add('Количество позиций в боксе должно быть не меньше 1');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreateProductDto(
      name: name,
      description: description,
      price: price,
      imageUrl: json['image_url']?.toString(),
      partnerId: partnerId,
      pointId: pointId,
      weight: weight,
      isAvailable: json['is_available'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      quantity: quantity,
      originalPrice: originalPrice,
      tags: tags,
      pickupStart: pickupStart,
      pickupEnd: pickupEnd,
      itemsCount: itemsCount,
    );
  }

  Map<String, dynamic> toEntityData() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'partner_id': partnerId,
      'point_id': pointId,
      'weight': weight,
      'is_available': isAvailable,
      'is_active': isActive,
      'quantity': quantity,
      'original_price': originalPrice,
      'tags': tags,
      'pickup_start': pickupStart,
      'pickup_end': pickupEnd,
      'items_count': itemsCount,
    };
  }
}
