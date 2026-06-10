import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../../theme/colors.dart';
import 'PaymentMethodScreen.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldLayout(
      pageTitle: 'Корзина',
      bodyContent: const _CartBody(),
      showNavBar: false,
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Корзина пуста',
        description: 'Загляните в раздел предложений и добавьте что-нибудь.',
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CartLine(item: cart.items[i]),
          ),
        ),
        _TotalRow(total: cart.totalPrice),
        _CheckoutButton(isLoading: cart.isCheckingOut),
      ],
    );
  }
}

class _CartLine extends ConsumerWidget {
  final CartItem item;

  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
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
                  item.product.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.pointName,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.product.price.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          _QtyControl(
            quantity: item.quantity,
            onMinus: () => notifier.updateQuantity(item.product.id, item.quantity - 1),
            onPlus: () => notifier.updateQuantity(item.product.id, item.quantity + 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => notifier.removeItem(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyButton(icon: Icons.remove, onTap: onMinus),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        _QtyButton(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE8FADC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.darkGreen),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;

  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Итого:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            '${total.toStringAsFixed(0)} ₽',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CheckoutButton extends ConsumerWidget {
  final bool isLoading;

  const _CheckoutButton({required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isLoading ? null : () => _checkout(context, ref),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Оформить заказ',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 0;
    if (userId <= 0) {
      showSnack('Войдите в аккаунт, чтобы оформить заказ', kind: SnackKind.error);
      return;
    }
    final orders = await ref.read(cartProvider.notifier).checkout(userId: userId);
    if (orders == null || orders.isEmpty) {
      final err = ref.read(cartProvider).error;
      showSnack(err ?? 'Не удалось оформить заказ', kind: SnackKind.error);
      return;
    }
    showSnack(
      'Заказ оформлен (${orders.length} шт.)',
      kind: SnackKind.success,
    );
    if (!context.mounted) return;
    // Пока платим только за первый заказ — поддержка мультиточечной
    // оплаты появится, когда backend научится создавать составной платёж.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(order: orders.first),
      ),
    );
  }
}
