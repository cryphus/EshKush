import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';

/// Страница точки продаж.
/// Показывает информацию о точке (название, адрес, рейтинг, часы, телефон)
/// и список продуктов с возможностью добавить в корзину.
class ProductPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProductPage({super.key, required this.data});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _state = AppState();

  // Мок-продукты точки (в реальном приложении — запрос к API /products/point/<id>)
  late final List<Map<String, dynamic>> _products;

  @override
  void initState() {
    super.initState();
    _products = _buildMockProducts();
  }

  List<Map<String, dynamic>> _buildMockProducts() {
    // Если в данных точки уже есть продукты — используем их
    if (widget.data['products'] is List) {
      return List<Map<String, dynamic>>.from(widget.data['products'] as List);
    }
    // Иначе генерируем мок-продукты на основе точки
    final name = widget.data['name'] ?? 'Товар';
    return [
      {
        'id': 1,
        'name': 'Набор дня · $name',
        'description': 'Ассорти из свежих продуктов по сниженной цене. Количество ограничено.',
        'price': widget.data['price'] ?? '199 ₽',
        'weight': '400 г',
        'is_available': true,
        'is_active': true,
      },
      {
        'id': 2,
        'name': 'Мини-набор',
        'description': 'Небольшой набор для одной персоны.',
        'price': '149 ₽',
        'weight': '200 г',
        'is_available': true,
        'is_active': true,
      },
      {
        'id': 3,
        'name': 'Выпечка дня',
        'description': 'Свежая выпечка, приготовленная сегодня.',
        'price': '99 ₽',
        'weight': '300 г',
        'is_available': false,
        'is_active': true,
      },
      {
        'id': 4,
        'name': 'Эко-набор',
        'description': 'Экологически чистые продукты от местных фермеров.',
        'price': '249 ₽',
        'weight': '500 г',
        'is_available': true,
        'is_active': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointInfo(),
                  const SizedBox(height: 20),
                  _buildInfoRow(),
                  const Divider(height: 32),
                  _buildProductsHeader(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: _ProductCard(
                  product: _products[i],
                  onAddToCart: _addToCart,
                  isGuest: _state.isGuest,
                ),
              ),
              childCount: _products.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final imageUrl = widget.data['image']?.toString() ?? '';

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.darkGreen,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white54,
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white54,
            child: Icon(Icons.favorite_border, color: Colors.white),
          ),
          onPressed: () {
            if (_state.isGuest) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Войдите, чтобы добавлять в избранное')),
              );
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkGreen.withOpacity(0.3),
                      child: const Icon(Icons.store,
                          size: 80, color: Colors.white30),
                    ),
                  )
                : Container(
                    color: AppColors.darkGreen.withOpacity(0.3),
                    child: const Icon(Icons.store,
                        size: 80, color: Colors.white30),
                  ),
            // Градиент снизу
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Логотип
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2), blurRadius: 8)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.data['logo'] != null
                      ? Image.network(
                          widget.data['logo'],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 64, height: 64),
                        )
                      : const SizedBox(width: 64, height: 64),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data['name'] ?? 'Точка продаж',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '${widget.data['rating'] ?? '0.0'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(отзывы)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Column(
      children: [
        _InfoTile(
          icon: Icons.location_on_outlined,
          title: 'Адрес',
          value: widget.data['address'] ?? 'Не указан',
        ),
        _InfoTile(
          icon: Icons.access_time_outlined,
          title: 'Часы работы',
          value: widget.data['time'] ??
              widget.data['working_hours'] ??
              'Не указано',
        ),
        _InfoTile(
          icon: Icons.phone_outlined,
          title: 'Телефон',
          value: widget.data['phone'] ?? 'Не указан',
        ),
      ],
    );
  }

  Widget _buildProductsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Доступные наборы',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    if (_state.isGuest) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Нужна авторизация'),
          content: const Text('Войдите, чтобы добавлять товары в корзину.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
              child: const Text('Войти',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    _state.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} добавлен в корзину'),
        action: SnackBarAction(
          label: 'Корзина',
          onPressed: () {
            Navigator.of(context).pushNamed(
              '/product',
              arguments: {'isCart': true},
            );
          },
        ),
      ),
    );
    setState(() {}); // обновить кнопки если нужно
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final void Function(Map<String, dynamic>) onAddToCart;
  final bool isGuest;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = (product['is_available'] as bool? ?? true) &&
        (product['is_active'] as bool? ?? true);

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFE8FADC)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fastfood_outlined,
                color: isAvailable ? AppColors.darkGreen : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            // Описание
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Товар',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product['weight'] != null) ...[
                        Text(
                          product['weight'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Недоступен',
                            style:
                                TextStyle(color: Colors.red, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Цена и кнопка
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product['price']?.toString() ?? '0 ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                isAvailable
                    ? GestureDetector(
                        onTap: () => onAddToCart(product),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'В корзину',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Недоступен',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
