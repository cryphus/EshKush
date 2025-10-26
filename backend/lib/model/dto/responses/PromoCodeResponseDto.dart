import '../../entities/PromoCodes.dart';

class PromoCodeResponseDto {
  final int id;
  final String code;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double minOrderSum;
  final String discountType;
  final double discountValue;
  final bool isActive;
  final int? usageLimit;
  final int currentUsage;
  final List<int>? applicableProducts;
  final List<int>? applicablePoints;

  PromoCodeResponseDto({
    required this.id,
    required this.code,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.minOrderSum,
    required this.discountType,
    required this.discountValue,
    required this.isActive,
    this.usageLimit,
    required this.currentUsage,
    this.applicableProducts,
    this.applicablePoints,
  });

  factory PromoCodeResponseDto.fromEntity(PromoCodes promoCodes) {
    return PromoCodeResponseDto(
      id: promoCodes.id,
      code: promoCodes.code,
      description: promoCodes.description,
      startDate: promoCodes.startDate,
      endDate: promoCodes.endDate,
      minOrderSum: promoCodes.minOrderSum,
      discountType: promoCodes.discountType.toString().split('.').last,
      discountValue: promoCodes.discountValue,
      isActive: promoCodes.isActive,
      usageLimit: promoCodes.usageLimit,
      currentUsage: promoCodes.currentUsage,
      applicableProducts: promoCodes.applicableProducts,
      applicablePoints: promoCodes.applicablePoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'min_order_sum': minOrderSum,
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_active': isActive,
      if (usageLimit != null) 'usage_limit': usageLimit,
      'current_usage': currentUsage,
      if (applicableProducts != null) 'applicable_products': applicableProducts,
      if (applicablePoints != null) 'applicable_points': applicablePoints,
    };
  }
}
