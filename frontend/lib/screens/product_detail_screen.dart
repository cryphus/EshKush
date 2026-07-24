import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';

/// Детальная страница товара ("сюрприз-бокса"): фото точки, остаток,
/// время самовывоза, непрямое описание содержимого, теги и кнопка покупки.
class ProductDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> data;

  const ProductDetailScreen({super.key, required this.data});

  Product? get _product => data['product'] is Product ? data['product'] as Product : null;
  Point? get _point => data['point'] is Point ? data['point'] as Point : null;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, Point point, bool isFav) async {
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

  void _buy(BuildContext context, WidgetRef ref, Product product, Point point) {
    ref.read(cartProvider.notifier).addItem(product, point.id, point.name);
    final error = ref.read(cartProvider).error;
    if (error == null) {
      showSnack('Добавлено в корзину', kind: SnackKind.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = _product;
    final point = _point;

    if (product == null || point == null) {
      return const Scaffold(
        body: Center(child: Text('Товар не найден')),
      );
    }

    final isFav = ref.watch(favoritesProvider).favorites.any((f) => f.id == point.id);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(context, ref, point, isFav),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildQuantityBadge(product),
                        const SizedBox(height: 16),
                        Text(
                          point.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB800), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              point.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoLine(Icons.location_on_outlined, point.address),
                        if (product.pickupWindowLabel != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoLine(
                            Icons.access_time,
                            'Самовывоз: ${product.pickupWindowLabel}',
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'Что вы найдёте внутри бокса:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.75),
                            height: 1.5,
                          ),
                        ),
                        if (product.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in product.tags) _buildTag(tag),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, ref, product, point),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context, WidgetRef ref, Point point, bool isFav) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.network(
            point.photoUrl,
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
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: () => _toggleFavorite(context, ref, point, isFav),
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
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityBadge(Product product) {
    if (product.quantity == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppColors.darkGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            '${product.quantity} шт. осталось',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String title) {
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
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkGreen),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, Product product, Point point) {
    final outOfStock = !product.isPurchasable;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      color: AppColors.colorBackground,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: outOfStock ? null : () => _buy(context, ref, product, point),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (product.hasDiscount) ...[
                Text(
                  '${product.originalPrice!.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                outOfStock ? 'Раскуплено' : 'Купить ${product.price.toStringAsFixed(0)} ₽',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
