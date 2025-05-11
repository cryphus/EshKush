import 'package:eshkush/widgets/cards/product_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../../theme/colors.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  int _currentNavIndex = 0;

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Бургерная',
      'rating': '4.8',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '299 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png'
    },
    {
      'name': 'Бургерная',
      'rating': '4.8',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '299 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: 'Предложения',
      bodyContent: _buildContent(),
      currentNavIndex: _currentNavIndex,
      onNavItemTapped: _handleNavItemTap,
    );
  }

  void _handleNavItemTap(int index) => setState(() => _currentNavIndex = index);

  Widget _buildContent() {
    return Column(
      children: [
        _buildActionButtons(),
        const SizedBox(height: 16),
        Expanded(
          child: ProductList(products: products),
        ),
      ],
    );
  }
}

Widget _buildActionButtons() {
  final actions = [
    {
      'title': 'Для вас',
      'icon': 'assets/icons/star.svg',
    },
    {
      'title': 'Карта',
      'icon': 'assets/icons/nav.svg',
    },
    {
      'title': 'Поиск',
      'icon': 'assets/icons/search.svg',
    },
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: actions
        .map((action) => _ActionButton(
              text: action['title']!,
              iconPath: action['icon']!,
            ))
        .toList(),
  );
}

class _ActionButton extends StatelessWidget {
  final String text;
  final String iconPath;

  const _ActionButton({
    required this.text,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.darkGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            color: AppColors.darkGreen,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}
