import '../../../utils/ValidationUtils.dart';

class CreatePromoCodeDto {
  final String code;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double minOrderSum;
  final String discountType;
  final double discountValue;
  final int? usageLimit;
  final List<int>? applicableProducts;
  final List<int>? applicablePoints;

  CreatePromoCodeDto({
    required this.code,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.minOrderSum,
    required this.discountType,
    required this.discountValue,
    this.usageLimit,
    this.applicableProducts,
    this.applicablePoints,
  });

  factory CreatePromoCodeDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final code = json['code']?.toString().trim().toUpperCase() ?? '';
    if (code.isEmpty || code.length < 3) {
      errors.add('Промокод должен быть минимум 3 символа');
    }

    final description = json['description']?.toString().trim() ?? '';
    if (description.isEmpty) {
      errors.add('Описание промокода обязательно');
    }

    final startDate = json['start_date'] != null
        ? DateTime.tryParse(json['start_date'].toString())
        : null;
    if (startDate == null) {
      errors.add('Некорректная дата начала');
    }

    final endDate = json['end_date'] != null
        ? DateTime.tryParse(json['end_date'].toString())
        : null;
    if (endDate == null) {
      errors.add('Некорректная дата окончания');
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      errors.add('Дата начала не может быть позже даты окончания');
    }

    final minOrderSum = json['min_order_sum'] != null
        ? double.tryParse(json['min_order_sum'].toString()) ?? 0.0
        : 0.0;
    if (minOrderSum < 0) {
      errors.add('Минимальная сумма заказа не может быть отрицательной');
    }

    final discountType = json['discount_type']?.toString().toLowerCase() ?? 'percentage';
    if (!['percentage', 'fixed'].contains(discountType)) {
      errors.add('Тип скидки должен быть percentage или fixed');
    }

    final discountValue = json['discount_value'] != null
        ? double.tryParse(json['discount_value'].toString()) ?? 0.0
        : 0.0;
    if (discountValue <= 0) {
      errors.add('Значение скидки должно быть положительным');
    }

    if (discountType == 'percentage' && discountValue > 100) {
      errors.add('Процентная скидка не может быть больше 100%');
    }

    final usageLimit = json['usage_limit'] != null
        ? int.tryParse(json['usage_limit'].toString())
        : null;
    if (usageLimit != null && usageLimit <= 0) {
      errors.add('Лимит использования должен быть положительным числом');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreatePromoCodeDto(
      code: code,
      description: description,
      startDate: startDate!,
      endDate: endDate!,
      minOrderSum: minOrderSum,
      discountType: discountType,
      discountValue: discountValue,
      usageLimit: usageLimit,
      applicableProducts: json['applicable_products'] != null
          ? List<int>.from(json['applicable_products'].map((e) => int.parse(e.toString())))
          : null,
      applicablePoints: json['applicable_points'] != null
          ? List<int>.from(json['applicable_points'].map((e) => int.parse(e.toString())))
          : null,
    );
  }

  Map<String, dynamic> toEntityData() {
    return {
      'code': code,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'min_order_sum': minOrderSum,
      'discount_type': discountType,
      'discount_value': discountValue,
      'usage_limit': usageLimit,
      'current_usage': 0,
      'applicable_products': applicableProducts,
      'applicable_points': applicablePoints,
    };
  }
}
