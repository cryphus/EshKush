import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import '../widgets/skeleton.dart';

class MainContent extends ConsumerStatefulWidget {
  final VoidCallback? onMoreOffers;
  final VoidCallback? onViewAllOrders;
  final VoidCallback? onViewAllCategories;

  const MainContent({
    super.key,
    this.onMoreOffers,
    this.onViewAllOrders,
    this.onViewAllCategories,
  });

  @override
  ConsumerState<MainContent> createState() => _MainContentState();
}

class _MainContentState extends ConsumerState<MainContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 0;
    if (userId > 0) {
      await ref.read(ordersProvider.notifier).loadUserOrders(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider);
    final userName = auth.user?.username ?? 'Гость';

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(userName),
            const SizedBox(height: 24),

            _buildSectionHeader('Ваши заказы', 'все', onTap: widget.onViewAllOrders),
            const SizedBox(height: 12),
            _buildOrdersSection(orders),
            const SizedBox(height: 16),

            _buildMoreOffersButton(),
            const SizedBox(height: 28),

            _buildSectionHeader('Категории', 'все', onTap: widget.onViewAllCategories),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(context, 'Магазины', 'assets/images/category_shops.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryCard(context, 'Рестораны', 'assets/images/category_restaurants.png'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(OrdersState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return Column(
        children: const [
          OrderCardSkeleton(),
          SizedBox(height: 8),
          OrderCardSkeleton(),
        ],
      );
    }
    if (state.error != null && state.orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Не удалось загрузить заказы',
          style: TextStyle(color: Colors.red.shade400, fontSize: 14),
        ),
      );
    }
    final active = state.orders
        .where((o) => o.isPending || o.status == OrderStatus.processing)
        .toList();
    if (active.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: const [
            Icon(Icons.receipt_long_outlined, color: Colors.black38, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'У вас пока нет активных заказов',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final order in active.take(3)) ...[
          _buildOrderCard(order),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildWelcomeBanner(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FADC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Привет,\n$userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Только в этом месяце\nты сохранил 2 кг еды!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
                if (!state.isGuest) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          color: Colors.blue, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Сэкономлено: ${state.moneySaved.toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/mascot.png',
              width: 110,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 110, height: 90),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTap: () {
        // TODO: навигация к деталям заказа
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF76A571),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.bakery_dining, color: Color(0xFFD4A44C), size: 30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заказ #${order.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)} ₽ • ${_formatStatus(order.status)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              tooltip: 'Действия с заказом',
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'cancel') {
                  _confirmCancelOrder(order);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Color(0xFFD32F2F), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Отменить заказ',
                        style: TextStyle(color: Color(0xFFD32F2F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Отменить заказ?'),
        content: Text(
          'Заказ #${order.id} будет отменён, '
          'а оплата (${order.totalPrice.toStringAsFixed(0)} ₽) '
          'возвращена на карту в течение нескольких дней.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await ref.read(ordersProvider.notifier).cancelOrder(order.id);
    if (!mounted) return;
    if (ok) {
      showSnack('Заказ отменён, средства будут возвращены',
          kind: SnackKind.success);
    } else {
      final err = ref.read(ordersProvider).error ?? 'Не удалось отменить заказ';
      showSnack(err, kind: SnackKind.error);
    }
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'ожидает';
      case OrderStatus.processing:
        return 'в работе';
      case OrderStatus.completed:
        return 'выполнен';
      case OrderStatus.cancelled:
        return 'отменён';
    }
  }

  Widget _buildMoreOffersButton() {
    return GestureDetector(
      onTap: widget.onMoreOffers,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Больше предложений',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        // TODO: фильтр по категории
      },
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFE8FADC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.asset(
                imagePath,
                height: 120,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 120,
                  child: Icon(Icons.fastfood, size: 50, color: AppColors.accentGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
