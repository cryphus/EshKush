import 'package:flutter/material.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../widgets/cards/product_list.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int _currentNavIndex = 0;

  final List<Map<String, dynamic>> favorites = [
    {
      'name': 'Суши-бар',
      'rating': '4.9',
      'distance': '0.8 км от вас',
      'time': '12:00 - 23:00',
      'price': '599 ₽',
      'image': 'http://example.com/sushi.png',
      'logo': 'http://example.com/sushi_logo.png',
      'isFavorite': true
    },
    {
      'name': 'Кофейня',
      'rating': '4.7',
      'distance': '0.5 км от вас',
      'time': '08:00 - 22:00',
      'price': '150 ₽',
      'image': 'http://example.com/coffee.png',
      'logo': 'http://example.com/coffee_logo.png',
      'isFavorite': true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: 'Избранное',
      bodyContent: _buildContent(),
      currentNavIndex: _currentNavIndex,
      onNavItemTapped: _handleNavItemTap,
    );
  }

  void _handleNavItemTap(int index) => setState(() => _currentNavIndex = index);

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(child: ProductList(products: favorites)),
      ],
    );
  }
}
