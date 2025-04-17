import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'OffersScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF0F4E4),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const darkGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFFC8E6C9);

  final List<Widget> _pages = [
    HomeContent(),
    OffersScreen(),
    Placeholder(), // Для третьей вкладки
    Placeholder(), // Для четвертой вкладки
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? _buildHomeAppBar() : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.black, size: 20),
              const SizedBox(width: 4),
              Text('Тюмень',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Icon(Icons.shopping_basket, color: darkGreen),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: lightGreen,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              width: 24,
              height: 24,
              color: _currentIndex == 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/products.svg',
              width: 24,
              height: 24,
              color: _currentIndex == 1
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
            label: 'Предложения',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/likes.svg',
              width: 24,
              height: 24,
              color: _currentIndex == 2
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/profile.svg',
              width: 24,
              height: 24,
              color: _currentIndex == 3
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
            label: 'Профиль',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final darkGreen = const Color(0xFF2E7D32);
  final lightGreen = const Color(0xFFC8E6C9);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Главная',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Привет,',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500)),
                      Text('Гость',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Только в этом месяце ты сохранил 2 кг еды!',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Image.network(
                  'http://91.186.217.192/images/packandearth.png',
                  width: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: 50, color: Colors.red),
                ),
              ],
            ),
          ),
          _buildSectionHeader('Ваши заказы', 'Все'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'http://91.186.217.192/images/shopicon.png',
                    width: 100,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('БулоШная',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 4),
                    Text('сегодня, 19:00 – 21:00',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lightGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {},
              child: Text('Больше предложений',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ),
          ),
          _buildSectionHeader('Категории', 'Все'),
          Row(
            children: [
              _buildCategoryCard(
                  'Магазины', 'http://91.186.217.192/images/shop.png'),
              const SizedBox(width: 16),
              _buildCategoryCard(
                  'Рестораны', 'http://91.186.217.192/images/restoraunt.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          TextButton(
            onPressed: () {},
            child: Text(action),
            style: TextButton.styleFrom(
                foregroundColor: darkGreen, textStyle: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imageUrl) {
    return Expanded(
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Image.network(
              imageUrl,
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error, size: 50, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class OffersContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('Специальные предложения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Здесь будут отображаться акции и скидки',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
