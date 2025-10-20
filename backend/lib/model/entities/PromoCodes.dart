import 'package:backend/model/enums/DiscountType.dart';

class PromoCodes {
  final int id;
  final String code;
  String description;
  DateTime startDate;
  DateTime endDate;
  double minOrderSum;
  DiscountType discountType;
  double discountValue;
  bool isActive;
  int? usageLimit;
  int currentUsage;
  List<int>? applicableProducts;
  List<int>? applicablePoints;

  PromoCodes({
    required this.id,
    required this.code,
    required this.description,
    required this.endDate,
    required this.startDate,
    required this.minOrderSum,
    required this.discountType,
    required this.discountValue,
    this.isActive = true,
    this.usageLimit,
    this.currentUsage = 0,
    this.applicableProducts,
    this.applicablePoints,
  }) {
    if (code.isEmpty) throw ArgumentError('Promo code cannot be empty');
    if (startDate.isAfter(endDate)) throw ArgumentError('Start date cannot be after end date');
    if (discountValue <= 0) throw ArgumentError('Discount value must be positive');
    if (minOrderSum < 0) throw ArgumentError('Minimum order sum cannot be negative');
    if (usageLimit != null && usageLimit! < 0) throw ArgumentError('Usage limit cannot be negative');
  }

  factory PromoCodes.fromJson(Map<String, dynamic> json) {
    return PromoCodes(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String? ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] as String? ?? DateTime.now().add(Duration(days: 30)).toIso8601String()),
      minOrderSum: double.tryParse(json['min_order_sum']?.toString() ?? '0') ?? 0.0,
      discountType: DiscountType.values.firstWhere(
        (e) => e.toString() == 'DiscountType.${json['discount_type']}',
        orElse: () => DiscountType.percentage,
      ),
      discountValue: double.tryParse(json['discount_value']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      usageLimit: json['usage_limit'] as int?,
      currentUsage: json['current_usage'] as int? ?? 0,
      applicableProducts: json['applicable_products'] != null 
          ? (json['applicable_products'] as List).map((e) => e as int).toList()
          : null,
      applicablePoints: json['applicable_points'] != null
          ? (json['applicable_points'] as List).map((e) => e as int).toList()
          : null,
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
      'discount_type': discountType.toString().split('.').last,
      'discount_value': discountValue,
      'is_active': isActive,
      'usage_limit': usageLimit,
      'current_usage': currentUsage,
      'applicable_products': applicableProducts,
      'applicable_points': applicablePoints,
    };
  }

  bool get isValid => isActive && 
      DateTime.now().isAfter(startDate) && 
      DateTime.now().isBefore(endDate) &&
      (usageLimit == null || currentUsage < usageLimit!);

  bool isApplicableToProduct(int productId) => 
      applicableProducts == null || applicableProducts!.contains(productId);

  bool isApplicableToPoint(int pointId) => 
      applicablePoints == null || applicablePoints!.contains(pointId);

  double calculateDiscount(double orderSum) {
    if (!isValid || orderSum < minOrderSum) return 0;
    
    return discountType == DiscountType.percentage
        ? orderSum * (discountValue / 100)
        : discountValue;
  }

  void incrementUsage() {
    if (usageLimit != null && currentUsage >= usageLimit!) {
      throw StateError('Promo code usage limit reached');
    }
    currentUsage++;
  }
}