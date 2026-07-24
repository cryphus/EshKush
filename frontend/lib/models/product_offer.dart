import 'point.dart';
import 'product.dart';

/// Карточка предложения на главном экране: конкретный товар + точка,
/// у которой его можно забрать. Приходит одним запросом из /products/feed
/// (без N+1 запроса за товарами каждой точки по отдельности).
class ProductOffer {
  final Product product;
  final Point point;

  const ProductOffer({required this.product, required this.point});

  factory ProductOffer.fromJson(Map<String, dynamic> json) => ProductOffer(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        point: Point.fromJson(json['point'] as Map<String, dynamic>),
      );
}
