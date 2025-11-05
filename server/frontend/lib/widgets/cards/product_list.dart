import 'package:flutter/material.dart';
import './product_card.dart';

class ProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const ProductList({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => ProductCard(data: products[index]),
    );
  }
}
