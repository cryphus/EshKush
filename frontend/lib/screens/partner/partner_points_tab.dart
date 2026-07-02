import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Вкладка управления точками продаж.
class PartnerPointsTab extends StatefulWidget {
  const PartnerPointsTab({super.key});

  @override
  State<PartnerPointsTab> createState() => _PartnerPointsTabState();
}

class _PartnerPointsTabState extends State<PartnerPointsTab> {
  final List<Map<String, dynamic>> _points = [
    {
      'id': 1,
      'name': 'Пекарня Bazbik — Центр',
      'address': 'ул. Ленина, д. 12',
      'category': 'Пекарня',
      'rating': 5.0,
      'openingHours': '07:00',
      'closingHours': '21:00',
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'Пекарня Bazbik — Север',
      'address': 'пр. Победы, д. 45',
      'category': 'Пекарня',
      'rating': 4.7,
      'openingHours': '08:00',
      'closingHours': '20:00',
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _points.length,
              itemBuilder: (ctx, i) => _PointCard(
                point: _points[i],
                onEdit: () => _editPoint(context, _points[i]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPoint(context),
        backgroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Добавить точку',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          const Text(
            'Мои точки продаж',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_points.length} точки',
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPoint(BuildContext context, Map<String, dynamic> point) {
    showDialog(
      context: context,
      builder: (ctx) => _PointEditDialog(point: point),
    ).then((updated) {
      if (updated != null) {
        setState(() {
          final idx = _points.indexWhere((p) => p['id'] == updated['id']);
          if (idx >= 0) _points[idx] = updated;
        });
      }
    });
  }

  void _addPoint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление новой точки — в разработке')),
    );
  }
}

class _PointCard extends StatelessWidget {
  final Map<String, dynamic> point;
  final VoidCallback onEdit;

  const _PointCard({required this.point, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FADC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store,
                    color: AppColors.darkGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      point['address'],
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.darkGreen),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                icon: Icons.access_time,
                text:
                    '${point['openingHours']} – ${point['closingHours']}',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.star,
                text: '${point['rating']}',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.category_outlined,
                text: point['category'],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.black54),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _PointEditDialog extends StatefulWidget {
  final Map<String, dynamic> point;

  const _PointEditDialog({required this.point});

  @override
  State<_PointEditDialog> createState() => _PointEditDialogState();
}

class _PointEditDialogState extends State<_PointEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.point['name'] as String);
    _addressCtrl =
        TextEditingController(text: widget.point['address'] as String);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать точку'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Адрес'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = {
              ...widget.point,
              'name': _nameCtrl.text,
              'address': _addressCtrl.text,
            };
            Navigator.of(context).pop(updated);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen),
          child: const Text('Сохранить',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
}
