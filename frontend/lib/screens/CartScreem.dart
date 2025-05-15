import 'package:flutter/material.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../widgets/cards/product_list.dart';
import '../../theme/colors.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _currentNavIndex = 0;

  final List<Map<String, dynamic>> cartItems = [
    {
      'name': 'Чизбургер',
      'rating': '4.8',
      'quantity': 2,
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '199 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'options': ['Без лука', 'Доп. соус'],
      'address': 'Улица Пушкина, дом 15',
      'working_hours': '09:00 - 23:00',
      'phone': '+7 (999) 123-45-67',
      'description': 'Подробное описание заведения...',
    },
    {
      'name': 'Картофель фри',
      'rating': '4.8',
      'quantity': 1,
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '150 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'options': ['Большая порция'],
      'address': 'Улица Пушкина, дом 15',
      'working_hours': '09:00 - 23:00',
      'phone': '+7 (999) 123-45-67',
      'description': 'Подробное описание заведения...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: 'Корзина',
      bodyContent: _buildContent(),
      showNavBar: false,
    );
  }

  void _handleNavItemTap(int index) => setState(() => _currentNavIndex = index);

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(child: ProductList(products: cartItems)),
        _buildTotalPrice(),
        _buildCheckoutButton(),
      ],
    );
  }

  Widget _buildTotalPrice() {
    final total = cartItems.fold(
        0,
        (sum, item) =>
            sum + int.parse(item['price']!.replaceAll(RegExp(r'[^0-9]'), '')));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Итого:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$total ₽',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text('Оформить заказ',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
