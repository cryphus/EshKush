import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/colors.dart'; // Убедитесь, что AppColors.darkGreen определен

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
      'name': 'Пекарня Bazbik',
      'rating': '5',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '199₽',
      'oldPrice': '350₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '4',
    },
    {
      'name': 'Кондитерская Besel',
      'rating': '4.8',
      'distance': '0.8 км от вас',
      'time': '19:00 - 22:00',
      'price': '189₽',
      'oldPrice': '340₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '2',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5), // Светлый фон из макета
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildActionButtons(),
            ),
            if (_isSearchVisible) _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _filteredProducts().length,
                itemBuilder: (context, index) {
                  return _ProductCard(data: _filteredProducts()[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = [
      {'title': 'Для вас', 'icon': 'icons/star.svg'},
      {'title': 'Карта', 'icon': 'icons/nav.svg'},
      {'title': 'Поиск', 'icon': 'icons/search.svg'},
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final bool isActive = _currentNavIndex == entry.key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: entry.key == 0 ? 0 : 5.0,
              right: entry.key == 2 ? 0 : 5.0,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentNavIndex = entry.key;
                  _isSearchVisible = (entry.key == 2) ? !_isSearchVisible : false;
                });
              },
              child: _ActionButton(
                text: entry.value['title']!,
                iconPath: entry.value['icon']!,
                isActive: isActive,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkGreen, width: 1.5),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Поиск...',
            prefixIcon: Icon(Icons.search, color: AppColors.darkGreen, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredProducts() {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((p) => p['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final bool isActive;

  const _ActionButton({required this.text, required this.iconPath, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8FADC) : Colors.white,
        border: Border.all(color: AppColors.darkGreen, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Основное изображение заведения
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  data['image'],
                  height: 100, 
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Логотип: слева, по центру вертикали, с отступом и скруглением
              Positioned(
                left: 15,   // Отступ от левого края
                top: 0,     // Растягиваем Positioned по всей высоте
                bottom: 0,  // чтобы Center сработал корректно
                child: Center(
                  child: Container(
                    width: 120, // Ширина логотипа
                    height: 75, // Высота логотипа
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Скругление углов подложки
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12), // Обрезка изображения по скругленным углам
                      child: Image.network(
                        data['logo'],
                        width: 120, // Ширина логотипа
                        height: 75, // Высота логотипа
                        fit: BoxFit.cover, // Растягивание изображения по размеру контейнера
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
                        Text(
                          ' ${data['rating']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          data['time'],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Иконка пакета с цифрой
                        SizedBox(
                          width: 25,
                          height: 25,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                'icons/bag_offer.svg',
                                fit: BoxFit.contain,
                                width: 25,
                                height: 25,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8), // Смещение цифры вниз внутрь пакета
                                child: Text(
                                  data['count'] ?? '1', // Берем количество из данных
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['distance'],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              data['oldPrice'],
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF8E8E8E),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF67945F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['price'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
