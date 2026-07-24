import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../theme/colors.dart';
import '../theme/decorations.dart';
import '../widgets/empty_state.dart';
import 'order_details_screen.dart';

/// Полный список заказов пользователя (в отличие от превью на главной,
/// где показаны только 3 активных).
class AllOrdersScreen extends ConsumerWidget {
  const AllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final orders = [...state.orders]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Ваши заказы'),
      ),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Заказов пока нет',
              description: 'Здесь появятся все ваши заказы.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _OrderRow(order: orders[index]),
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (order.status) {
      OrderStatus.pending => ('Ожидает', AppColors.statusYellowDark, AppColors.statusYellowBg),
      OrderStatus.processing => ('В работе', AppColors.darkGreen, AppColors.veryLightGray),
      OrderStatus.completed => ('Выполнен', AppColors.darkGreen, AppColors.veryLightGray),
      OrderStatus.cancelled => ('Отменён', const Color(0xFFD32F2F), const Color(0xFFFDEAEA)),
    };
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заказ #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(order.date)} · ${order.totalPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }
}
