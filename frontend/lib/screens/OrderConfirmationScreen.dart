import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/payment_transaction.dart';
import '../theme/colors.dart';
import '../widgets/layouts/scaffold_layout.dart';

/// Экран успешной оплаты с "чеком".
class OrderConfirmationScreen extends StatelessWidget {
  final Order order;
  final PaymentTransaction transaction;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: 'Заказ оплачен',
      showNavBar: false,
      bodyContent: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 56),
            ),
            const SizedBox(height: 16),
            const Text(
              'Спасибо за заказ!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Покажите этот экран на точке для получения заказа',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            _ReceiptCard(order: order, transaction: transaction),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text(
                  'На главную',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Order order;
  final PaymentTransaction transaction;

  const _ReceiptCard({required this.order, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Чек',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('Заказ', '#${order.id}'),
          _row('Транзакция', transaction.providerTransactionId),
          _row('Способ оплаты', _methodLabel(transaction.paymentMethod)),
          _row('Дата', _formatDate(transaction.transactionDate)),
          _row('Товаров', order.productsId.length.toString()),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Итого',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${transaction.orderPrice.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
      case PaymentMethod.creditCard:
        return 'Карта';
      case PaymentMethod.mobilePayment:
        return 'СБП';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.other:
        return 'Другое';
    }
  }

  String _formatDate(DateTime date) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
