import 'package:backend/model/enums/DiscountType.dart';

class PromoCodes {
  final int id;
  final String code;
  String description;
  DateTime startDate;
  DateTime endDate;
  final double minOrderSum;
  DiscountType discountType;
  double discountValue;
  bool isActive;
  int? usageLimit;
  int currentUsage;
  final List<int>? applicableProducts;
  final List<int>? applicablePoints;

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
      code: json['code'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      minOrderSum: (json['minOrderSum'] as num).toDouble(),
      discountType: DiscountType.values.firstWhere(
        (e) => e.toString() == 'DiscountType.${json['discountType']}',
        orElse: () => DiscountType.percentage,
      ),
      discountValue: (json['discountValue'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      usageLimit: json['usageLimit'] as int?,
      currentUsage: json['currentUsage'] as int? ?? 0,
      applicableProducts: json['applicableProducts'] != null 
          ? (json['applicableProducts'] as List).map((e) => e as int).toList()
          : null,
      applicablePoints: json['applicablePoints'] != null
          ? (json['applicablePoints'] as List).map((e) => e as int).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'minOrderSum': minOrderSum,
      'discountType': discountType.toString().split('.').last,
      'discountValue': discountValue,
      'isActive': isActive,
      'usageLimit': usageLimit,
      'currentUsage': currentUsage,
      'applicableProducts': applicableProducts,
      'applicablePoints': applicablePoints,
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