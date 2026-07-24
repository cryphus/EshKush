import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/point_api_service.dart';
import '../api/product_api_service.dart';
import '../models/order.dart';
import '../models/point.dart';
import '../models/product.dart';
import '../providers/orders_provider.dart';
import '../theme/colors.dart';
import '../theme/decorations.dart';
import '../utils/snackbar.dart';

/// Экран деталей одного заказа: заведение, состав, статус, отмена.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  final _pointApi = PointApiService();
  final _productApi = ProductApiService();

  bool _isLoading = true;
  String? _error;
  Point? _point;
  List<MapEntry<Product, int>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final point = await _pointApi.getPointById(widget.order.pointId);

      final counts = <int, int>{};
      for (final id in widget.order.productsId) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
      final products = await Future.wait(
        counts.keys.map((id) => _productApi.getProductById(id)),
      );
      final items = [
        for (final p in products) MapEntry(p, counts[p.id] ?? 1),
      ];

      if (!mounted) return;
      setState(() {
        _point = point;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Отменить заказ?'),
        content: Text(
          'Заказ #${widget.order.id} будет отменён, а оплата '
          '(${widget.order.totalPrice.toStringAsFixed(0)} ₽) возвращена на карту '
          'в течение нескольких дней.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(ordersProvider.notifier).cancelOrder(widget.order.id);
    if (!mounted) return;
    if (ok) {
      showSnack('Заказ отменён, средства будут возвращены', kind: SnackKind.success);
      Navigator.of(context).pop();
    } else {
      final err = ref.read(ordersProvider).error ?? 'Не удалось отменить заказ';
      showSnack(err, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text('Заказ #${order.id}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _StatusCard(order: order),
                      const SizedBox(height: 16),
                      if (_point != null) _PointCard(point: _point!),
                      const SizedBox(height: 16),
                      const Text(
                        'Состав заказа',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      for (final entry in _items) ...[
                        _ProductLine(product: entry.key, quantity: entry.value),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      _TotalCard(order: order),
                      if (order.isPending || order.status == OrderStatus.processing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _confirmCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD32F2F),
                              side: const BorderSide(color: Color(0xFFD32F2F)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Отменить заказ'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить заказ', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Order order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (order.status) {
      OrderStatus.pending => ('Ожидает подтверждения', AppColors.statusYellowDark, AppColors.statusYellowBg),
      OrderStatus.processing => ('В работе', AppColors.darkGreen, AppColors.veryLightGray),
      OrderStatus.completed => ('Выполнен', AppColors.darkGreen, AppColors.veryLightGray),
      OrderStatus.cancelled => ('Отменён', const Color(0xFFD32F2F), const Color(0xFFFDEAEA)),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_formatDate(order.date), style: const TextStyle(color: AppColors.textMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}, ${two(date.hour)}:${two(date.minute)}';
  }
}

class _PointCard extends StatelessWidget {
  final Point point;

  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: {'point': point}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.network(
                  point.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      point.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductLine extends StatelessWidget {
  final Product product;
  final int quantity;

  const _ProductLine({required this.product, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: product.imageUrl == null
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 8),
          Text('×$quantity', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 10),
          Text(
            '${(product.price * quantity).toStringAsFixed(0)} ₽',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final Order order;

  const _TotalCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.veryLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Итого', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(
            '${order.totalPrice.toStringAsFixed(0)} ₽',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkGreen),
          ),
        ],
      ),
    );
  }
}
