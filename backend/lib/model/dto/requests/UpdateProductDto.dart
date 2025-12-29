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
    return data;
  }

  bool get hasFields => toEntityData().isNotEmpty;
}
