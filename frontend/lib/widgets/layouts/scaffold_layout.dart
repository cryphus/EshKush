import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/connectivity_provider.dart';
import '../../theme/colors.dart';
import '../../screens/cart_screen.dart';

class ScaffoldLayout extends StatefulWidget {
  final String pageTitle;
  final Widget bodyContent;
  final bool showNavBar;
  final int currentNavIndex;
  final ValueChanged<int>? onNavItemTapped;

  const ScaffoldLayout({
    super.key,
    required this.pageTitle,
    required this.bodyContent,
    this.showNavBar = true,
    this.currentNavIndex = 0,
    this.onNavItemTapped,
  });

  @override
  State<ScaffoldLayout> createState() => _ScaffoldLayoutState();
}

class _ScaffoldLayoutState extends State<ScaffoldLayout> {
  String _selectedCity = 'Тюмень';

  // TODO: загружать из БД
  final List<String> _cities = [
    'Тюмень',
    'Москва',
    'Санкт-Петербург',
    'Екатеринбург',
    'Новосибирск',
    'Казань',
  ];

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Выберите город',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._cities.map((city) => ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: city == _selectedCity ? AppColors.accentGreen : Colors.grey,
                  ),
                  title: Text(
                    city,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: city == _selectedCity ? FontWeight.w600 : FontWeight.normal,
                      color: city == _selectedCity ? AppColors.accentGreen : Colors.black87,
                    ),
                  ),
                  trailing: city == _selectedCity
                      ? const Icon(Icons.check, color: AppColors.accentGreen)
                      : null,
                  onTap: () {
                    setState(() => _selectedCity = city);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pageTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: widget.bodyContent),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showNavBar ? _buildBottomNavBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showCityPicker,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.black, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCity,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: SvgPicture.asset(
                'assets/icons/cart.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomNavBar() => Container(
        decoration: const BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 76,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  iconPath: 'assets/icons/home.svg',
                  isActive: widget.currentNavIndex == 0,
                  onTap: () => widget.onNavItemTapped?.call(0),
                ),
                _NavItem(
                  iconPath: 'assets/icons/products.svg',
                  isActive: widget.currentNavIndex == 1,
                  onTap: () => widget.onNavItemTapped?.call(1),
                ),
                _NavItem(
                  iconPath: 'assets/icons/like.svg',
                  isActive: widget.currentNavIndex == 2,
                  onTap: () => widget.onNavItemTapped?.call(2),
                ),
                _NavItem(
                  iconPath: 'assets/icons/profile.svg',
                  isActive: widget.currentNavIndex == 3,
                  onTap: () => widget.onNavItemTapped?.call(3),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Полоска "нет сети" сверху экрана. Скрывается, когда сеть появляется.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(connectivityProvider).maybeWhen(
          data: (offline) => offline,
          orElse: () => false,
        );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isOffline ? 28 : 0,
      width: double.infinity,
      color: const Color(0xFFD32F2F),
      alignment: Alignment.center,
      child: isOffline
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Нет подключения к интернету',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            )
          : null,
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: 20,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
