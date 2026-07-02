import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Вкладка заказов партнёра.
class PartnerOrdersTab extends StatefulWidget {
  const PartnerOrdersTab({super.key});

  @override
  State<PartnerOrdersTab> createState() => _PartnerOrdersTabState();
}

class _PartnerOrdersTabState extends State<PartnerOrdersTab> {
  String _statusFilter = 'all';

  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#1024',
      'customerName': 'Алексей К.',
      'items': ['Набор дня', 'Мини-набор'],
      'total': '348 ₽',
      'point': 'Пекарня Bazbik — Центр',
      'date': '28 февр., 19:42',
      'status': 'completed',
      'statusLabel': 'Выполнен',
    },
    {
      'id': '#1023',
      'customerName': 'Мария С.',
      'items': ['Эко-набор'],
      'total': '249 ₽',
      'point': 'Пекарня Bazbik — Север',
      'date': '28 февр., 18:30',
      'status': 'completed',
      'statusLabel': 'Выполнен',
    },
    {
      'id': '#1022',
      'customerName': 'Иван П.',
      'items': ['Хлеб ржаной', 'Мини-набор', 'Набор дня'],
      'total': '427 ₽',
      'point': 'Пекарня Bazbik — Центр',
      'date': '28 февр., 17:15',
      'status': 'cancelled',
      'statusLabel': 'Отменён',
    },
    {
      'id': '#1021',
      'customerName': 'Анна Б.',
      'items': ['Выпечка дня'],
      'total': '99 ₽',
      'point': 'Пекарня Bazbik — Центр',
      'date': '27 февр., 20:00',
      'status': 'completed',
      'statusLabel': 'Выполнен',
    },
    {
      'id': '#1020',
      'customerName': 'Дмитрий М.',
      'items': ['Набор дня'],
      'total': '199 ₽',
      'point': 'Пекарня Bazbik — Север',
      'date': '27 февр., 19:30',
      'status': 'processing',
      'statusLabel': 'В обработке',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'all') return _orders;
    return _orders.where((o) => o['status'] == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Заказов нет',
                        style: TextStyle(color: Colors.black38)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _OrderCard(
                      order: _filtered[i],
                      onView: () => _viewOrder(context, _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filters = [
      {'label': 'Все', 'value': 'all'},
      {'label': 'Выполнены', 'value': 'completed'},
      {'label': 'В обработке', 'value': 'processing'},
      {'label': 'Отменены', 'value': 'cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Заказы',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_filtered.length} заказов',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = _statusFilter == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _statusFilter = f['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.darkGreen
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.darkGreen
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black54,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _viewOrder(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Заказ ${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Покупатель', order['customerName']),
            _detailRow('Точка', order['point']),
            _detailRow('Дата', order['date']),
            _detailRow('Итого', order['total']),
            const Divider(),
            const Text('Позиции:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...(order['items'] as List).map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 8, color: AppColors.darkGreen),
                    const SizedBox(width: 6),
                    Text(item as String),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.black54)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

// ── Карточка заказа ───────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onView;

  const _OrderCard({required this.order, required this.onView});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final statusColor = switch (status) {
      'completed' => Colors.green,
      'cancelled' => Colors.red,
      'processing' => Colors.orange,
      _ => Colors.grey,
    };

    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order['customerName'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                Text(
                  order['total'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              (order['items'] as List).join(' · '),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 13, color: Colors.black38),
                const SizedBox(width: 4),
                Text(
                  order['date'],
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black38),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['statusLabel'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
