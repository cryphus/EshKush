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

  final List<Widget> _pages = [
    const MainContent(),
    const OffersPage(),
    const FavoritesPage(),
    const ProfilePage(),
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: _pageTitles[_currentIndex],
      bodyContent: _buildPageContent(),
      currentNavIndex: _currentIndex,
      onNavItemTapped: _onNavItemTapped,
      showNavBar: true,
    );
  }

  Widget _buildPageContent() => IndexedStack(
        index: _currentIndex,
        children: _pages,
      );
}
