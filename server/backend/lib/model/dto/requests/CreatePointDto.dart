import '../../../utils/ValidationUtils.dart';

class CreatePointDto {
  final String name;
  final String address;
  final int cityId;
  final Map<String, dynamic> products;
  final String openingHours;
  final String closingHours;
  final int partnerId;
  final double longitude;
  final double latitude;
  final Map<String, dynamic> tags;

  CreatePointDto({
    required this.name,
    required this.address,
    required this.cityId,
    required this.products,
    required this.openingHours,
    required this.closingHours,
    required this.partnerId,
    required this.longitude,
    required this.latitude,
    required this.tags,
  });

  factory CreatePointDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty || !ValidationUtils.isValidName(name)) {
      errors.add('Некорректное название точки');
    }

    final address = json['address']?.toString().trim() ?? '';
    if (address.isEmpty) {
      errors.add('Адрес обязателен');
    }

    final cityId = json['city_id'] != null ? int.tryParse(json['city_id'].toString()) ?? 0 : 0;
    if (cityId <= 0) {
      errors.add('Некорректный ID города');
    }

    final partnerId = json['partner_id'] != null ? int.tryParse(json['partner_id'].toString()) ?? 0 : 0;
    if (partnerId <= 0) {
      errors.add('Некорректный ID партнера');
    }

    final longitude = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString()) ?? 0.0
        : 0.0;
    if (longitude < -180 || longitude > 180) {
      errors.add('Некорректная долгота (должна быть от -180 до 180)');
    }

    final latitude = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString()) ?? 0.0
        : 0.0;
    if (latitude < -90 || latitude > 90) {
      errors.add('Некорректная широта (должна быть от -90 до 90)');
    }

    final openingHours = json['opening_hours']?.toString().trim() ?? '';
    if (!_isValidTime(openingHours)) {
      errors.add('Некорректный формат времени открытия (ожидается HH:mm)');
    }

    final closingHours = json['closing_hours']?.toString().trim() ?? '';
    if (!_isValidTime(closingHours)) {
      errors.add('Некорректный формат времени закрытия (ожидается HH:mm)');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreatePointDto(
      name: name,
      address: address,
      cityId: cityId,
      products: json['products'] as Map<String, dynamic>? ?? {},
      openingHours: openingHours,
      closingHours: closingHours,
      partnerId: partnerId,
      longitude: longitude,
      latitude: latitude,
      tags: json['tags'] as Map<String, dynamic>? ?? {},
    );
  }

  static bool _isValidTime(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(time);
  }

  Map<String, dynamic> toEntityData() {
    return {
      'name': name,
      'address': address,
      'city_id': cityId,
      'products': products,
      'opening_hours': openingHours,
      'closing_hours': closingHours,
      'partner_id': partnerId,
      'longitude': longitude,
      'latitude': latitude,
      'tags': tags,
    };
  }
}
