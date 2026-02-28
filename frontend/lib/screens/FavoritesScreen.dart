import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import 'ProductPage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _state = AppState();

  // Мок-список избранных (для авторизованных пользователей)
  final List<Map<String, dynamic>> _favorites = [
    {
      'name': 'Суши-бар Тоо',
      'rating': '4.9',
      'distance': '0.8 км от вас',
      'time': '12:00 - 23:00',
      'price': '299 ₽',
      'oldPrice': '500 ₽',
      'count': '3',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'address': 'ул. Абая, д. 24',
      'working_hours': '12:00 - 23:00',
      'phone': '+7 (999) 345-67-89',
      'description': 'Наборы суши и роллов по сниженной цене.',
    },
    {
      'name': 'Кофейня Уют',
      'rating': '4.7',
      'distance': '0.5 км от вас',
      'time': '08:00 - 22:00',
      'price': '150 ₽',
      'oldPrice': '250 ₽',
      'count': '2',
      'image': 'http://91.186.217.192/images/img_shopicon.png',
      'logo': 'http://91.186.217.192/images/img_shopicon.png',
      'address': 'ул. Мира, д. 3',
      'working_hours': '08:00 - 22:00',
      'phone': '+7 (999) 456-78-90',
      'description': 'Свежие кофе и выпечка по утрам.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_state.isGuest) return _buildGuestContent();
    return _buildFavoritesContent();
  }

  // ── Гость ────────────────────────────────────────────────────────────────────
  Widget _buildGuestContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                size: 80, color: AppColors.darkGreen),
            const SizedBox(height: 16),
            const Text(
              'Сохраняйте любимые точки',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Войдите в аккаунт, чтобы добавлять\nточки в избранное и быстро их находить.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Войти в аккаунт',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Список избранного ────────────────────────────────────────────────────────
  Widget _buildFavoritesContent() {
    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.black26),
            const SizedBox(height: 16),
            const Text(
              'Пока ничего нет',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажмите ♡ на точке продаж,\nчтобы добавить в избранное',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _favorites.length,
      itemBuilder: (ctx, i) => _FavoriteCard(
        data: _favorites[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductPage(data: _favorites[i]),
          ),
        ),
        onRemove: () => setState(() => _favorites.removeAt(i)),
      ),
    );
  }
}

// ── Карточка избранного ───────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Логотип
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Image.network(
                data['logo'] ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFE8FADC),
                  child: const Icon(Icons.store,
                      color: AppColors.darkGreen, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Инфо
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFB800), size: 14),
                        Text(
                          ' ${data['rating']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.black54),
                        Text(
                          ' ${data['distance']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 13, color: Colors.black54),
                        Text(
                          ' ${data['time']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Цена
                    Row(
                      children: [
                        if (data['oldPrice'] != null) ...[
                          Text(
                            data['oldPrice'],
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          data['price'] ?? '',
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Кнопка удаления из избранного
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
