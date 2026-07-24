import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/city.dart';
import '../../providers/city_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../theme/colors.dart';
import '../../theme/decorations.dart';
import '../../screens/cart_screen.dart';

class ScaffoldLayout extends ConsumerStatefulWidget {
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
  ConsumerState<ScaffoldLayout> createState() => _ScaffoldLayoutState();
}

class _ScaffoldLayoutState extends ConsumerState<ScaffoldLayout> {
  void _showCityPicker() {
    final cities = ref.read(citiesProvider).valueOrNull ?? const <City>[];
    if (cities.isEmpty) return;
    final selected = ref.read(selectedCityProvider) ?? cities.first;

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
            ...cities.map((city) => ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: city.id == selected.id ? AppColors.accentGreen : Colors.grey,
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: city.id == selected.id ? FontWeight.w600 : FontWeight.normal,
                      color: city.id == selected.id ? AppColors.accentGreen : Colors.black87,
                    ),
                  ),
                  trailing: city.id == selected.id
                      ? const Icon(Icons.check, color: AppColors.accentGreen)
                      : null,
                  onTap: () {
                    ref.read(selectedCityProvider.notifier).state = city;
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
    // Когда список городов загрузился, а город ещё не выбран — выбираем первый.
    ref.listen(citiesProvider, (prev, next) {
      final list = next.valueOrNull;
      if (list != null &&
          list.isNotEmpty &&
          ref.read(selectedCityProvider) == null) {
        ref.read(selectedCityProvider.notifier).state = list.first;
      }
    });

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

  PreferredSizeWidget _buildAppBar() {
    final cities = ref.watch(citiesProvider).valueOrNull ?? const <City>[];
    final selectedCity = ref.watch(selectedCityProvider) ??
        (cities.isNotEmpty ? cities.first : null);

    return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showCityPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.darkGreen, size: 17),
                    const SizedBox(width: 5),
                    Text(
                      selectedCity?.name ?? 'Город',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.black38, size: 18),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.subtle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/cart.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBottomNavBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.card,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.veryLightGray : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isActive ? AppColors.darkGreen : Colors.black26,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
