import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/product_api_service.dart';
import '../models/point.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import 'CartScreem.dart';

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
        style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7), height: 1.5),
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
              showSnack('Добавлено в корзину', kind: SnackKind.success);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.store, size: 60, color: Colors.grey)),
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
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, size: 24),
            ),
          ),
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
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
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
          _tag(
            e.value?.toString() ?? e.key,
            AppColors.accentGreen,
          ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
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

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _ProductRow({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.grey.shade200,
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
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
            onPressed: product.isAvailable ? onAdd : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('+'),
          ),
        ],
      ),
    );
  }
}
