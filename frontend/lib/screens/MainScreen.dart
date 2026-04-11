import 'package:eshkush/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import './HomeScreen.dart';
import './OffersScreen.dart';
import './FavoritesScreen.dart';

import '../widgets/layouts/scaffold_layout.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<String> _pageTitles = [
    'Главная',
    'Предложения',
    'Избранное',
    'Профиль',
  ];

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: _pageTitles[_currentIndex],
      bodyContent: _buildPageContent(),
      currentNavIndex: _currentIndex,
      onNavItemTapped: _switchToTab,
      showNavBar: true,
    );
  }

  Widget _buildPageContent() => IndexedStack(
        index: _currentIndex,
        children: [
          MainContent(
            onMoreOffers: () => _switchToTab(1),
            onViewAllOrders: () {
              // TODO: экран всех заказов
            },
            onViewAllCategories: () => _switchToTab(1),
          ),
          const OffersPage(),
          const FavoritesPage(),
          const ProfilePage(),
        ],
      );
}
