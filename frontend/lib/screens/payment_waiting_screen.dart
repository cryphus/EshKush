import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/payment_provider.dart';
import '../theme/colors.dart';
import '../widgets/layouts/scaffold_layout.dart';
import 'order_confirmation_screen.dart';

/// Экран ожидания подтверждения оплаты.
/// Запускает polling статуса платежа через [PaymentNotifier.startPolling].
/// При успехе — переводит на [OrderConfirmationScreen]. При отказе — показывает
/// кнопку повторить.
class PaymentWaitingScreen extends ConsumerStatefulWidget {
  final Order order;

  const PaymentWaitingScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentWaitingScreen> createState() =>
      _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState
    extends ConsumerState<PaymentWaitingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(paymentProvider.notifier)
          .startPolling(orderId: widget.order.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentProvider, (_, next) {
      if (next.isCompleted && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              order: widget.order,
              transaction: next.transaction!,
            ),
          ),
        );
      }
    });

    final state = ref.watch(paymentProvider);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(paymentProvider.notifier).stopPolling();
        }
      },
      child: ScaffoldLayout(
        pageTitle: 'Оплата',
        showNavBar: false,
        bodyContent: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildContent(state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PaymentState state) {
    if (state.isFailed) {
      return _StatusCard(
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        title: 'Оплата не прошла',
        subtitle: state.transaction?.errorMessage ??
            'Платёж был отклонён или отменён.',
        primaryLabel: 'Попробовать снова',
        onPrimary: () => Navigator.of(context).pop(),
        secondaryLabel: 'В корзину',
        onSecondary: () =>
            Navigator.of(context).popUntil((r) => r.isFirst),
      );
    }

    if (state.isRefunded) {
      return _StatusCard(
        icon: Icons.history,
        iconColor: Colors.orange,
        title: 'Заказ возвращён',
        subtitle: 'Средства скоро вернутся на вашу карту.',
        primaryLabel: 'На главную',
        onPrimary: () =>
            Navigator.of(context).popUntil((r) => r.isFirst),
      );
    }

    // pending / polling
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.darkGreen),
        const SizedBox(height: 24),
        const Text(
          'Ждём подтверждение оплаты',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Завершите оплату в открывшемся окне YooKassa. Как только статус обновится — мы покажем чек.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Проверить сейчас'),
          onPressed: () =>
              ref.read(paymentProvider.notifier).refreshStatus(widget.order.id),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            ref.read(paymentProvider.notifier).stopPolling();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 72, color: iconColor),
        const SizedBox(height: 16),
        Text(title,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onPrimary,
            child: Text(primaryLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}
