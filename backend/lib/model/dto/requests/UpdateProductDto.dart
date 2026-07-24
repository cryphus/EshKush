import '../../../utils/ValidationUtils.dart';

class UpdateProductDto {
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final int? partnerId;
  final int? pointId;
  final double? weight;
  final bool? isAvailable;
  final bool? isActive;
  final int? quantity;
  final double? originalPrice;
  final List<String>? tags;
  final String? pickupStart;
  final String? pickupEnd;
  final int? itemsCount;

  UpdateProductDto({
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.partnerId,
    this.pointId,
    this.weight,
    this.isAvailable,
    this.isActive,
    this.quantity,
    this.originalPrice,
    this.tags,
    this.pickupStart,
    this.pickupEnd,
    this.itemsCount,
  });

  factory UpdateProductDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final name = json['name']?.toString().trim();
    if (name != null && name.isNotEmpty && !ValidationUtils.isValidName(name)) {
      errors.add('Некорректное название продукта');
    }

    final description = json['description']?.toString().trim();
    if (description != null && description.isNotEmpty && description.length > 1000) {
      errors.add('Описание не должно превышать 1000 символов');
    }

    final price = json['price'] != null ? double.tryParse(json['price'].toString()) : null;
    if (price != null && price <= 0) {
      errors.add('Цена должна быть положительным числом');
    }

    final pointId = json['point_id'] != null ? int.tryParse(json['point_id'].toString()) : null;
    if (pointId != null && pointId <= 0) {
      errors.add('Некорректный ID точки');
    }

    final partnerId = json['partner_id'] != null ? int.tryParse(json['partner_id'].toString()) : null;
    if (partnerId != null && partnerId <= 0) {
      errors.add('Некорректный ID партнера');
    }

    final weight = json['weight'] != null ? double.tryParse(json['weight'].toString()) : null;
    if (weight != null && weight < 0) {
      errors.add('Вес должен быть неотрицательным числом');
    }

    final quantity = json['quantity'] != null ? int.tryParse(json['quantity'].toString()) : null;
    if (quantity != null && quantity < 0) {
      errors.add('Количество товара не может быть отрицательным');
    }

    final originalPrice = json['original_price'] != null
        ? double.tryParse(json['original_price'].toString())
        : null;
    if (originalPrice != null && originalPrice < 0) {
      errors.add('Старая цена не может быть отрицательной');
    }

    final tags = json['tags'] == null
        ? null
        : (json['tags'] as List).map((e) => e.toString()).toList();

    final pickupStart = json['pickup_start']?.toString();
    final pickupEnd = json['pickup_end']?.toString();

    final itemsCount =
        json['items_count'] != null ? int.tryParse(json['items_count'].toString()) : null;
    if (itemsCount != null && itemsCount < 1) {
      errors.add('Количество позиций в боксе должно быть не меньше 1');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return UpdateProductDto(
      name: name,
      description: description,
      price: price,
      imageUrl: json['image_url']?.toString(),
      partnerId: partnerId,
      pointId: pointId,
      weight: weight,
      isAvailable: json['is_available'] as bool?,
      isActive: json['is_active'] as bool?,
      quantity: quantity,
      originalPrice: originalPrice,
      tags: tags,
      pickupStart: pickupStart,
      pickupEnd: pickupEnd,
      itemsCount: itemsCount,
    );
  }

  Map<String, dynamic> toEntityData() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (partnerId != null) data['partner_id'] = partnerId;
    if (pointId != null) data['point_id'] = pointId;
    if (weight != null) data['weight'] = weight;
    if (isAvailable != null) data['is_available'] = isAvailable;
    if (isActive != null) data['is_active'] = isActive;
    if (quantity != null) data['quantity'] = quantity;
    if (originalPrice != null) data['original_price'] = originalPrice;
    if (tags != null) data['tags'] = tags;
    if (pickupStart != null) data['pickup_start'] = pickupStart;
    if (pickupEnd != null) data['pickup_end'] = pickupEnd;
    if (itemsCount != null) data['items_count'] = itemsCount;
    return data;
  }

  bool get hasFields => toEntityData().isNotEmpty;
}
