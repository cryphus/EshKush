import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/colors.dart';
import '../../screens/CartScreem.dart';

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
  static const List<String> _navIcons = [
    'assets/icons/home.svg',
    'assets/icons/products.svg',
    'assets/icons/like.svg',
    'assets/icons/profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: _buildAppBar(),
      body: _buildBody(context),
      bottomNavigationBar: widget.showNavBar ? _buildBottomNavBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLocationInfo(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
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

  Widget _buildLocationInfo() => const Row(
        children: [
          Icon(Icons.location_on, color: Colors.black, size: 20),
          SizedBox(width: 4),
          Text(
            'Город',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildBody(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pageTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: widget.bodyContent),
          ],
        ),
      );

  Widget _buildBottomNavBar() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: AppColors.lightGreen,
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _navIcons.length,
              (index) => _NavItem(
                iconPath: _navIcons[index],
                isActive: widget.currentNavIndex == index,
                onTap: () => widget.onNavItemTapped?.call(index),
              ),
            ),
          ),
        ),
      );
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 28,
            height: 28,
            color: AppColors.white,
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
