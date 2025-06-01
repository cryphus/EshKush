import 'base/BaseMap.dart';

class ProductCategoryMap extends BaseMap {
  final int productId;
  final int categoryId;

  ProductCategoryMap({
    required this.productId,
    required this.categoryId,
    required DateTime createdAt,
  }) : super(createdAt: createdAt) {
    validateIds();
  }

  @override
  void validateIds() {
    if (productId <= 0) {
      throw ArgumentError('ID продукта должен быть положительным числом');
    }
    if (categoryId <= 0) {
      throw ArgumentError('ID категории должен быть положительным числом');
    }
  }

  factory ProductCategoryMap.fromJson(Map<String, dynamic> json) {
    return ProductCategoryMap(
      productId: json['product_id'] as int,
      categoryId: json['category_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategoryMap &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          categoryId == other.categoryId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => productId.hashCode ^ categoryId.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'ProductCategoryMap(productId: $productId, categoryId: $categoryId, createdAt: $createdAt)';
}