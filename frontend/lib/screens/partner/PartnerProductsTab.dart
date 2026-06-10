import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Вкладка управления продуктами.
/// Позволяет включать/выключать продукты и редактировать их.
class PartnerProductsTab extends StatefulWidget {
  const PartnerProductsTab({super.key});

  @override
  State<PartnerProductsTab> createState() => _PartnerProductsTabState();
}

class _PartnerProductsTabState extends State<PartnerProductsTab> {
  String _selectedPointFilter = 'Все точки';

  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Набор дня',
      'description': 'Ассорти свежей выпечки',
      'price': 199.0,
      'weight': '400 г',
      'point': 'Пекарня Bazbik — Центр',
      'is_available': true,
      'is_active': true,
      'sold': 12,
    },
    {
      'id': 2,
      'name': 'Мини-набор',
      'description': 'Небольшой набор для одной персоны',
      'price': 149.0,
      'weight': '200 г',
      'point': 'Пекарня Bazbik — Центр',
      'is_available': true,
      'is_active': true,
      'sold': 8,
    },
    {
      'id': 3,
      'name': 'Выпечка дня',
      'description': 'Свежая выпечка',
      'price': 99.0,
      'weight': '300 г',
      'point': 'Пекарня Bazbik — Север',
      'is_available': false,
      'is_active': true,
      'sold': 0,
    },
    {
      'id': 4,
      'name': 'Эко-набор',
      'description': 'Экологичные продукты',
      'price': 249.0,
      'weight': '500 г',
      'point': 'Пекарня Bazbik — Север',
      'is_available': true,
      'is_active': true,
      'sold': 4,
    },
    {
      'id': 5,
      'name': 'Хлеб ржаной',
      'description': 'Свежий ржаной хлеб',
      'price': 79.0,
      'weight': '500 г',
      'point': 'Пекарня Bazbik — Центр',
      'is_available': true,
      'is_active': false, // Выключен владельцем
      'sold': 0,
    },
  ];

  List<String> get _pointOptions {
    final points = _products.map((p) => p['point'] as String).toSet().toList();
    return ['Все точки', ...points];
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedPointFilter == 'Все точки') return _products;
    return _products
        .where((p) => p['point'] == _selectedPointFilter)
        .toList();
  }

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
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final realIdx =
                    _products.indexOf(_filtered[i]);
                return _ProductCard(
                  product: _filtered[i],
                  onToggleAvailable: () => _toggleAvailable(realIdx),
                  onToggleActive: () => _toggleActive(realIdx),
                  onEdit: () => _editProduct(context, realIdx),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProduct(context),
        backgroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Добавить продукт',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Продукты',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Фильтр по точке
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _pointOptions.map((opt) {
                final isSelected = _selectedPointFilter == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPointFilter = opt),
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
                        opt,
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

  void _toggleAvailable(int idx) {
    setState(() {
      _products[idx]['is_available'] =
          !(_products[idx]['is_available'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (_products[idx]['is_available'] as bool)
              ? '${_products[idx]['name']} — доступен для заказа'
              : '${_products[idx]['name']} — скрыт от покупателей',
        ),
      ),
    );
  }

  void _toggleActive(int idx) {
    setState(() {
      _products[idx]['is_active'] =
          !(_products[idx]['is_active'] as bool);
    });
  }

  void _editProduct(BuildContext context, int idx) {
    showDialog(
      context: context,
      builder: (_) => _ProductEditDialog(product: _products[idx]),
    ).then((updated) {
      if (updated != null) {
        setState(() => _products[idx] = updated);
      }
    });
  }

  void _addProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление продукта — в разработке')),
    );
  }
}

// ── Карточка продукта ─────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onToggleAvailable;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;

  const _ProductCard({
    required this.product,
    required this.onToggleAvailable,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['is_available'] as bool;
    final isActive = product['is_active'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive && isAvailable
                      ? const Color(0xFFE8FADC)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fastfood_outlined,
                  color: isActive && isAvailable
                      ? AppColors.darkGreen
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      product['point'] as String,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${(product['price'] as double).toInt()} ₽',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive
                      ? AppColors.darkGreen
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.black38, size: 20),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Переключатель "Активен"
              Expanded(
                child: _SwitchRow(
                  label: 'Включён',
                  value: isActive,
                  onChanged: (_) => onToggleActive(),
                ),
              ),
              const SizedBox(width: 12),
              // Переключатель "Доступен для заказа"
              Expanded(
                child: _SwitchRow(
                  label: 'Доступен',
                  value: isAvailable,
                  onChanged: isActive ? (_) => onToggleAvailable() : null,
                ),
              ),
            ],
          ),
          if (product['sold'] != null && (product['sold'] as int) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Продано: ${product['sold']} шт.',
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.darkGreen,
          ),
        ),
      ],
    );
  }
}

// ── Диалог редактирования ─────────────────────────────────────────────────────

class _ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const _ProductEditDialog({required this.product});

  @override
  State<_ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<_ProductEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.product['name'] as String);
    _descCtrl = TextEditingController(
        text: widget.product['description'] as String);
    _priceCtrl = TextEditingController(
        text: (widget.product['price'] as double).toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать продукт'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              decoration:
                  const InputDecoration(labelText: 'Цена (₽)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = {
              ...widget.product,
              'name': _nameCtrl.text,
              'description': _descCtrl.text,
              'price':
                  double.tryParse(_priceCtrl.text) ?? widget.product['price'],
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
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }
}
