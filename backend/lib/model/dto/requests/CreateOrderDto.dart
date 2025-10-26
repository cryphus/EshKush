import '../../../utils/ValidationUtils.dart';

class CreateOrderDto {
  final List<int> productsId;
  final int userId;
  final int pointId;
  final double totalPrice;
  final DateTime? date;

  CreateOrderDto({
    required this.productsId,
    required this.userId,
    required this.pointId,
    required this.totalPrice,
    this.date,
  });

  factory CreateOrderDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final productsId = json['products_id'] != null
        ? List<int>.from(json['products_id'].map((e) => int.parse(e.toString())))
        : <int>[];
    
    if (productsId.isEmpty) {
      errors.add('Список продуктов обязателен');
    }

    final userId = json['user_id'] != null ? int.parse(json['user_id'].toString()) : 0;
    if (userId <= 0) {
      errors.add('Некорректный ID пользователя');
    }

    final pointId = json['point_id'] != null ? int.parse(json['point_id'].toString()) : 0;
    if (pointId <= 0) {
      errors.add('Некорректный ID точки');
    }

    final totalPrice = json['total_price'] != null
        ? double.parse(json['total_price'].toString())
        : 0.0;
    if (totalPrice <= 0) {
      errors.add('Сумма заказа должна быть больше 0');
    }

    final date = json['date'] != null
        ? DateTime.tryParse(json['date'].toString())
        : null;

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreateOrderDto(
      productsId: productsId,
      userId: userId,
      pointId: pointId,
      totalPrice: totalPrice,
      date: date,
    );
  }

  Map<String, dynamic> toEntityData() {
    return {
      'products_id': productsId,
      'user_id': userId,
      'point_id': pointId,
      'total_price': totalPrice,
      'date': date?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
