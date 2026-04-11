import 'product.dart';

class CartItem {
  final Product product;
  final int pointId;
  final String pointName;
  int quantity;

  CartItem({
    required this.product,
    required this.pointId,
    required this.pointName,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
