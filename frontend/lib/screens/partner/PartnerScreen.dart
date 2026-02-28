import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../state/app_state.dart';
import 'PartnerDashboardTab.dart';
import 'PartnerPointsTab.dart';
import 'PartnerProductsTab.dart';
import 'PartnerOrdersTab.dart';

/// Главный экран веб-панели партнёра.
/// Содержит боковую/нижнюю навигацию и 4 вкладки.
class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  int _selectedTab = 0;

  final _tabs = const [
    _TabInfo(icon: Icons.dashboard_outlined, label: 'Дашборд'),
    _TabInfo(icon: Icons.store_outlined, label: 'Точки'),
    _TabInfo(icon: Icons.inventory_2_outlined, label: 'Продукты'),
    _TabInfo(icon: Icons.receipt_long_outlined, label: 'Заказы'),
  ];

  Widget get _currentTabContent => switch (_selectedTab) {
        0 => const PartnerDashboardTab(),
        1 => const PartnerPointsTab(),
        2 => const PartnerProductsTab(),
        3 => const PartnerOrdersTab(),
        _ => const PartnerDashboardTab(),
      };

  @override
  Widget build(BuildContext context) {
    // Проверяем доступ — только для партнёров
    if (!AppState().isPartner && AppState().userName != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: const Center(
          child: Text('Эта панель доступна только для партнёров.'),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── Широкий экран (боковое меню) ────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        _SideBar(
          selectedIndex: _selectedTab,
          tabs: _tabs,
          onSelect: (i) => setState(() => _selectedTab = i),
          onBack: () => Navigator.of(context).pop(),
        ),
        Expanded(child: _currentTabContent),
      ],
    );
  }

  // ── Узкий экран (нижняя навигация) ──────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Заголовок
        Container(
          color: AppColors.darkGreen,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Панель партнёра',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Контент
        Expanded(child: _currentTabContent),
        // Нижняя навигация
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: Row(
            children: List.generate(
              _tabs.length,
              (i) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabs[i].icon,
                          color: _selectedTab == i
                              ? AppColors.darkGreen
                              : Colors.black38,
                          size: 24,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tabs[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _selectedTab == i
                                ? AppColors.darkGreen
                                : Colors.black38,
                            fontWeight: _selectedTab == i
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Вспомогательные классы ────────────────────────────────────────────────────

class _TabInfo {
  final IconData icon;
  final String label;
  const _TabInfo({required this.icon, required this.label});
}

class _SideBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabInfo> tabs;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;

  const _SideBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: double.infinity,
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          // Лого
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EshKush',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Панель партнёра',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Пункты меню
          ...List.generate(
            tabs.length,
            (i) => _SideBarItem(
              icon: tabs[i].icon,
              label: tabs[i].label,
              isSelected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          ),
          const Spacer(),
          // Назад
          _SideBarItem(
            icon: Icons.arrow_back,
            label: 'Вернуться',
            isSelected: false,
            onTap: onBack,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SideBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
