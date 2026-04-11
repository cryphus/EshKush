import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../models/payment_transaction.dart';
import '../providers/payment_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import '../widgets/layouts/scaffold_layout.dart';
import 'PaymentWaitingScreen.dart';

/// Экран выбора способа оплаты.
/// Принимает созданный заказ, создаёт платёж в YooKassa и открывает
/// страницу подтверждения во внешнем браузере.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  final Order order;

  const PaymentMethodScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethod _selected = PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);

    return ScaffoldLayout(
      pageTitle: 'Оплата заказа',
      showNavBar: false,
      bodyContent: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _OrderSummary(order: widget.order),
            const SizedBox(height: 24),
            const Text(
              'Способ оплаты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _MethodTile(
              method: PaymentMethod.card,
              title: 'Банковская карта',
              subtitle: 'Visa · MasterCard · МИР',
              icon: Icons.credit_card,
              selected: _selected == PaymentMethod.card,
              onTap: () => setState(() => _selected = PaymentMethod.card),
            ),
            _MethodTile(
              method: PaymentMethod.mobilePayment,
              title: 'СБП',
              subtitle: 'Оплата через приложение банка',
              icon: Icons.qr_code_2,
              selected: _selected == PaymentMethod.mobilePayment,
              onTap: () =>
                  setState(() => _selected = PaymentMethod.mobilePayment),
            ),
            const SizedBox(height: 24),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: state.isInitiating ? null : _startPayment,
                child: state.isInitiating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Оплатить ${widget.order.totalPrice.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата проходит на защищённой странице YooKassa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment() async {
    final notifier = ref.read(paymentProvider.notifier);
    final success = await notifier.initiate(
      orderId: widget.order.id,
      paymentMethod: _selected,
    );
    if (!success || !mounted) return;

    final url = ref.read(paymentProvider).confirmationUrl;
    if (url == null) {
      showSnack('Не удалось получить ссылку на оплату', kind: SnackKind.error);
      return;
    }

    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      showSnack('Не удалось открыть страницу оплаты', kind: SnackKind.error);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentWaitingScreen(order: widget.order),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final Order order;
  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Заказ #${order.id}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Товаров: ${order.productsId.length}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('К оплате:',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                '${order.totalPrice.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? AppColors.darkGreen : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                      selected ? AppColors.darkGreen : Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: selected ? method : null,
                onChanged: (_) => onTap(),
                activeColor: AppColors.darkGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
