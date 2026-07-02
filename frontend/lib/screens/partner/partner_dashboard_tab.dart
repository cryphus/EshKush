import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../state/app_state.dart';

/// Дашборд партнёра — статистика и сводка.
class PartnerDashboardTab extends StatelessWidget {
  const PartnerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Популярные продукты'),
          const SizedBox(height: 12),
          _buildPopularProducts(),
          const SizedBox(height: 24),
          _buildSectionTitle('Последние заказы'),
          const SizedBox(height: 12),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = AppState().userName ?? 'Партнёр';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Добро пожаловать, $name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Сводка за последние 30 дней',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      const _StatData(
        label: 'Заказов',
        value: '24',
        icon: Icons.receipt_long_outlined,
        color: Colors.blue,
        change: '+12%',
        positive: true,
      ),
      const _StatData(
        label: 'Выручка',
        value: '14 800 ₽',
        icon: Icons.attach_money,
        color: Colors.green,
        change: '+8%',
        positive: true,
      ),
      const _StatData(
        label: 'Продуктов',
        value: '6',
        icon: Icons.inventory_2_outlined,
        color: Colors.orange,
        change: '0%',
        positive: true,
      ),
      const _StatData(
        label: 'Рейтинг',
        value: '4.8 ★',
        icon: Icons.star_outline,
        color: Colors.purple,
        change: '+0.2',
        positive: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (ctx, i) => _StatCard(data: stats[i]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPopularProducts() {
    final products = [
      {'name': 'Набор дня', 'sold': 12, 'revenue': '2 388 ₽'},
      {'name': 'Мини-набор', 'sold': 8, 'revenue': '1 192 ₽'},
      {'name': 'Эко-набор', 'sold': 4, 'revenue': '996 ₽'},
    ];

    return Column(
      children: products.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FADC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fastfood,
                    color: AppColors.darkGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${p['sold']} шт.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                p['revenue'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentOrders() {
    final orders = [
      {'id': '#1024', 'time': '19:42', 'items': 2, 'total': '348 ₽', 'status': 'completed'},
      {'id': '#1023', 'time': '18:30', 'items': 1, 'total': '199 ₽', 'status': 'completed'},
      {'id': '#1022', 'time': '17:15', 'items': 3, 'total': '597 ₽', 'status': 'cancelled'},
    ];

    return Column(
      children: orders.map((o) {
        final isCompleted = o['status'] == 'completed';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Text(
                o['id'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                o['time'] as String,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const Spacer(),
              Text('${o['items']} поз.  '),
              Text(
                o['total'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isCompleted ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Выполнен' : 'Отменён',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Вспомогательные данные ────────────────────────────────────────────────────

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool positive;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.positive,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.color, size: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (data.positive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.change,
                  style: TextStyle(
                    color:
                        data.positive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data.label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
