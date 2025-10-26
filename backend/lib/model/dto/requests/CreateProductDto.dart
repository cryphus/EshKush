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
    };
  }
}
