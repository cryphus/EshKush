import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/product_api_service.dart';
import '../models/point.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/point_reviews_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class ProductPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const ProductPage({super.key, required this.data});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final ProductApiService _productsApi = ProductApiService();

  late final Point? _point;
  bool _isLoadingProducts = false;
  String? _productsError;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _point = widget.data['point'] is Point ? widget.data['point'] as Point : null;
    if (_point != null) {
      _loadProducts(_point!.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(favoritesProvider.notifier).load();
        ref.read(pointReviewsProvider(_point!.id).notifier).load();
      });
    }
  }

  Future<void> _toggleFavorite(bool isFav) async {
    final point = _point;
    if (point == null) return;
    try {
      if (isFav) {
        await ref.read(favoritesProvider.notifier).remove(point.id);
        showSnack('Удалено из избранного', kind: SnackKind.info);
      } else {
        await ref.read(favoritesProvider.notifier).add(point);
        showSnack('Добавлено в избранное', kind: SnackKind.success);
      }
    } catch (e) {
      showApiError(e);
    }
  }

  Future<void> _loadProducts(int pointId) async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });
    try {
      final list = await _productsApi.getProductsByPoint(pointId);
      if (!mounted) return;
      setState(() {
        _products = list;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildTitleRow(),
                        const SizedBox(height: 6),
                        _buildInfoLine(
                          Icons.location_on_outlined,
                          _point?.address ?? widget.data['address']?.toString() ?? '—',
                          subtitle: 'РЯДОМ С ВАМИ',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoLine(
                          Icons.access_time,
                          'Сегодня',
                          subtitle: _point?.workingHours ??
                              widget.data['time']?.toString() ??
                              '—',
                        ),
                        const SizedBox(height: 16),
                        _buildTags(),
                        const SizedBox(height: 20),
                        const Text(
                          'Меню',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildProductsList(),
                        const SizedBox(height: 24),
                        if (_point != null) ...[
                          _buildReviewsSection(_point!),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, cart),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_point == null) {
      return Text(
        widget.data['description']?.toString() ?? '',
        style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.7), height: 1.5),
      );
    }
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_productsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const Text('Не удалось загрузить меню'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadProducts(_point!.id),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Пока нет доступных позиций', style: TextStyle(color: Colors.black54)),
      );
    }
    return Column(
      children: [
        for (final p in _products) ...[
          _ProductRow(
            product: p,
            onAdd: () {
              ref.read(cartProvider.notifier).addItem(
                    p,
                    _point!.id,
                    _point!.name,
                  );
            },
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(
                    data: {'product': p, 'point': _point},
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    final photoUrl = _point?.photoUrl;
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: photoUrl == null
              ? Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.store, size: 60, color: Colors.grey)),
                )
              : Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.store, size: 60, color: Colors.grey)),
                  ),
                ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, size: 24),
            ),
          ),
        ),
        if (_point != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Builder(builder: (context) {
              final isFav = ref
                  .watch(favoritesProvider)
                  .favorites
                  .any((f) => f.id == _point!.id);
              return GestureDetector(
                onTap: () => _toggleFavorite(isFav),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? Colors.redAccent : Colors.black87,
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildTitleRow() {
    final name = _point?.name ?? widget.data['name']?.toString() ?? 'Название';
    final rating = _point?.rating.toStringAsFixed(1) ??
        widget.data['rating']?.toString() ??
        '5';
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
        const SizedBox(width: 4),
        Text(
          rating,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLine(IconData icon, String title, {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ],
    );
  }

  Widget _buildTags() {
    final tagEntries = _point?.tags.entries.take(4).toList() ?? const [];
    if (tagEntries.isEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _tag('заведение', AppColors.accentGreen),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in tagEntries)
          _tag(e.key, AppColors.accentGreen),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Widget _buildReviewsSection(Point point) {
    final reviewsState = ref.watch(pointReviewsProvider(point.id));
    final auth = ref.watch(authProvider);
    final canReview = auth.isAuthenticated && !auth.isGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Отзывы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (reviewsState.reviews.isNotEmpty)
              Text(
                '(${reviewsState.reviews.length})',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const Spacer(),
            if (canReview)
              TextButton(
                onPressed: () => _openReviewForm(point.id),
                child: const Text('Оставить отзыв'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviewsState.isLoading && reviewsState.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (reviewsState.reviews.isEmpty)
          const Text(
            'Пока нет отзывов — будьте первым.',
            style: TextStyle(color: Colors.black54),
          )
        else
          for (final review in reviewsState.reviews) ...[
            _ReviewCard(review: review),
            const SizedBox(height: 8),
          ],
        if (!canReview) ...[
          const SizedBox(height: 8),
          Text(
            auth.isAuthenticated
                ? 'Гостям недоступно оставлять отзывы — войдите в аккаунт.'
                : 'Войдите, чтобы оставить отзыв.',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ],
    );
  }

  Future<void> _openReviewForm(int pointId) async {
    double rating = 5;
    bool isSubmitting = false;
    final controller = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оставить отзыв',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return IconButton(
                      onPressed: () => setSheetState(() => rating = starValue.toDouble()),
                      icon: Icon(
                        starValue <= rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Комментарий (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);
                            final ok = await ref
                                .read(pointReviewsProvider(pointId).notifier)
                                .submit(rating: rating, comment: controller.text);
                            if (!ctx.mounted) return;
                            if (ok) {
                              Navigator.of(ctx).pop(true);
                            } else {
                              setSheetState(() => isSubmitting = false);
                              final error = ref.read(pointReviewsProvider(pointId)).error;
                              showSnack(error ?? 'Не удалось отправить отзыв',
                                  kind: SnackKind.error);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Отправить'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (result == true) {
      showSnack('Спасибо за отзыв!', kind: SnackKind.success);
    }
  }

  Widget _buildBottomBar(BuildContext context, CartState cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: cart.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            cart.isEmpty
                ? 'Добавьте что-нибудь в корзину'
                : 'В корзину • ${cart.totalItems} шт. • ${cart.totalPrice.toStringAsFixed(0)} ₽',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

}

/// Обесцвечивает [child], если [grey] — используется для "раскупленных" товаров.
Widget _maybeGreyscale(bool grey, Widget child) {
  if (!grey) return child;
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    child: child,
  );
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  const _ProductRow({required this.product, required this.onAdd, this.onTap});

  @override
  Widget build(BuildContext context) {
    final outOfStock = !product.isPurchasable;
    return Opacity(
      opacity: outOfStock ? 0.55 : 1.0,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _maybeGreyscale(
                  outOfStock,
                  product.imageUrl == null
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        )
                      : Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (outOfStock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Раскуплено',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: outOfStock ? null : onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('+'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName ?? 'Пользователь',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < review.rating.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
