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
  bool _isSearchVisible = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Бургерная',
      'rating': '4.8',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '299 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'address': 'Улица Пушкина, дом 15',
      'working_hours': '09:00 - 23:00',
      'phone': '+7 (999) 123-45-67',
      'description': 'Подробное описание заведения...',
    },
    {
      'name': 'Пиццерия',
      'rating': '4.5',
      'distance': '2.1 км от вас',
      'time': '18:00 - 22:00',
      'price': '499 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'address': 'Улица Лермонтова, дом 7',
      'working_hours': '10:00 - 24:00',
      'phone': '+7 (999) 765-43-21',
      'description': 'Лучшая пицца в городе',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildActionButtons((index) {
          if (index == 2) {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) _searchQuery = '';
            });
          }
        }),
        if (_isSearchVisible) _buildSearchBar(),
        const SizedBox(height: 16),
        Expanded(
          child: ProductList(products: _filteredProducts()),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.darkGreen,
            width: 2.0,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Поиск...',
            prefixIcon: const Icon(Icons.search, color: AppColors.darkGreen),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredProducts() {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((product) =>
            product['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildActionButtons(Function(int) onActionTap) {
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
          .asMap()
          .entries
          .map((entry) => GestureDetector(
                onTap: () => onActionTap(entry.key),
                child: _ActionButton(
                  text: entry.value['title']!,
                  iconPath: entry.value['icon']!,
                  isActive: entry.key == 2 && _isSearchVisible,
                ),
              ))
          .toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final bool isActive;

  const _ActionButton({
    required this.text,
    required this.iconPath,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.darkGreen.withOpacity(0.1)
            : Colors.transparent,
        border: Border.all(
          color: isActive ? AppColors.darkGreen : AppColors.darkGreen,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            color: isActive ? AppColors.darkGreen : AppColors.darkGreen,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isActive ? AppColors.darkGreen : AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}
