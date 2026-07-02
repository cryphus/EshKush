import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../models/payment_transaction.dart';
import '../providers/payment_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import 'payment_waiting_screen.dart';

/// Экран выбора способа оплаты (дизайн «Оплата ЮKassa»).
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
    final priceLabel = widget.order.totalPrice.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: 'Оплата', onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _OrderCard(order: widget.order),
                    _SectionCard(
                      label: 'Способ оплаты',
                      child: Column(
                        children: [
                          _MethodTile(
                            title: 'Банковская карта',
                            subtitle: 'Visa · MasterCard · МИР',
                            leading: const _CardChip(),
                            selected: _selected == PaymentMethod.card,
                            onTap: () =>
                                setState(() => _selected = PaymentMethod.card),
                          ),
                          const SizedBox(height: 8),
                          _MethodTile(
                            title: 'СБП',
                            subtitle: 'Система быстрых платежей',
                            leading: const _SbpBadge(),
                            selected: _selected == PaymentMethod.mobilePayment,
                            onTap: () => setState(
                                () => _selected = PaymentMethod.mobilePayment),
                          ),
                        ],
                      ),
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const Opacity(
                      opacity: 0.5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: Color(0xFF666666)),
                          SizedBox(width: 6),
                          Text(
                            'Защищено ЮKassa · SSL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            _PayFooter(
              priceLabel: priceLabel,
              isLoading: state.isInitiating,
              onPay: _startPayment,
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

/// Шапка экрана: круглая кнопка «назад» и заголовок по центру.
class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Белая карточка-секция с бежевым заголовком-капсом.
class _SectionCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _SectionCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.labelBeige,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'Ваш заказ',
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8D8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFF9A8068), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Товаров: ${order.productsId.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 12, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(order.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${order.totalPrice.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.brandGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)} ${two(date.hour)}:${two(date.minute)}';
  }
}

/// Плитка способа оплаты в стиле дизайна: выбранная — зелёная рамка и фон.
class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreenPale : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandGreen : AppColors.borderBeige,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brandGreen : const Color(0xFFCCCCCC),
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Синяя «карточка» с магнитной полосой — иконка банковской карты.
class _CardChip extends StatelessWidget {
  const _CardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 26,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A40A0), Color(0xFF2264E0)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 7,
            child: Container(
              height: 7,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            left: 5,
            bottom: 4,
            child: Container(
              width: 10,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бейдж «СБП».
class _SbpBadge extends StatelessWidget {
  const _SbpBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Text(
        'СБП',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF3060C0),
        ),
      ),
    );
  }
}

/// Бежевый футер: «Итого к оплате» и кнопка оплаты.
class _PayFooter extends StatelessWidget {
  final String priceLabel;
  final bool isLoading;
  final VoidCallback onPay;

  const _PayFooter({
    required this.priceLabel,
    required this.isLoading,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      color: AppColors.footerBeige,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Итого к оплате',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '$priceLabel ₽',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : onPay,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Оплатить $priceLabel ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
