import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';
import 'ProductPage.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  int _currentNavIndex = 0;
  bool _isSearchVisible = false;
  String _searchQuery = '';

  // Список точек продаж с предложениями
  final List<Map<String, dynamic>> _points = [
    {
      'name': 'Пекарня Bazbik',
      'rating': '5.0',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '199 ₽',
      'oldPrice': '350 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '4',
      'address': 'ул. Ленина, д. 12',
      'working_hours': '19:30 - 21:00',
      'phone': '+7 (999) 123-45-67',
      'description': 'Свежая выпечка по сниженным ценам в конце рабочего дня. Хлеб, булочки, пироги.',
    },
    {
      'name': 'Кондитерская Besel',
      'rating': '4.8',
      'distance': '0.8 км от вас',
      'time': '19:00 - 22:00',
      'price': '189 ₽',
      'oldPrice': '340 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '2',
      'address': 'пр. Победы, д. 5',
      'working_hours': '19:00 - 22:00',
      'phone': '+7 (999) 234-56-78',
      'description': 'Торты, пирожные и десерты по специальным ценам.',
    },
    {
      'name': 'Суши & Роллы Тоо',
      'rating': '4.7',
      'distance': '2.1 км от вас',
      'time': '20:00 - 22:30',
      'price': '299 ₽',
      'oldPrice': '500 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '3',
      'address': 'ул. Абая, д. 24',
      'working_hours': '20:00 - 22:30',
      'phone': '+7 (999) 345-67-89',
      'description': 'Наборы суши и ролов по сниженной цене. Свежие, вкусные, доступные.',
    },
    {
      'name': 'Кафе Зелёный сад',
      'rating': '4.9',
      'distance': '0.5 км от вас',
      'time': '18:30 - 21:00',
      'price': '149 ₽',
      'oldPrice': '270 ₽',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'count': '5',
      'address': 'ул. Садовая, д. 8',
      'working_hours': '18:30 - 21:00',
      'phone': '+7 (999) 456-78-90',
      'description': 'Домашняя еда и напитки. Экологичная упаковка.',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _points;
    return _points
        .where((p) =>
            (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFilterButtons(),
            ),
            if (_isSearchVisible) _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  return _PointCard(
                    data: _filtered[index],
                    onTap: () => _openPointDetail(context, _filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final buttons = [
      {'title': 'Для вас', 'icon': 'icons/star.svg'},
      {'title': 'Карта', 'icon': 'icons/nav.svg'},
      {'title': 'Поиск', 'icon': 'icons/search.svg'},
    ];

    return Row(
      children: buttons.asMap().entries.map((entry) {
        final isActive = _currentNavIndex == entry.key;
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
                  _isSearchVisible =
                      entry.key == 2 ? !_isSearchVisible : false;
                });
              },
              child: _FilterButton(
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkGreen, width: 1.5),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Поиск точек...',
            prefixIcon:
                Icon(Icons.search, color: AppColors.darkGreen, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  void _openPointDetail(BuildContext context, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductPage(data: data),
      ),
    );
  }
}

// ── Фильтр-кнопка ────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final bool isActive;

  const _FilterButton({
    required this.text,
    required this.iconPath,
    required this.isActive,
  });

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
            colorFilter:
                const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Карточка точки продаж ─────────────────────────────────────────────────────

class _PointCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _PointCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение с логотипом
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    data['image'] ?? '',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFE8FADC),
                      child: const Icon(Icons.store,
                          size: 48, color: AppColors.darkGreen),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          data['logo'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store, color: AppColors.darkGreen),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Инфо
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star,
                              color: Color(0xFFFFB800), size: 15),
                          Text(
                            ' ${data['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 13, color: Colors.black54),
                          const SizedBox(width: 3),
                          Text(
                            data['time'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Пакет с количеством
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.darkGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                data['count'] ?? '1',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['distance'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      // Цены
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                data['oldPrice'] ?? '',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF8E8E8E),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.darkGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['price'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
      ),
    );
  }
}
