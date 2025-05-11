import 'package:flutter/material.dart';
import '../services/FrontendAuthService.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = FrontendAuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppColors.colorBackground,
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
  List<String> navIconsUrls = [];
  bool _isLoadingIcons = true;

  @override
  void initState() {
    super.initState();
    _loadNavIcons();
  }

  Future<void> _loadNavIcons() async {
    try {
      setState(() {
        navIconsUrls = [
          'assets/icons/home.svg',
          'assets/icons/like.svg',
          'assets/icons/products.svg',
          'assets/icons/profile.svg',
        ];
        _isLoadingIcons = false;
      });
    } catch (e) {
      print('Ошибка загрузки иконок: $e');
      setState(() => _isLoadingIcons = false);
    }
  }

  Widget _buildSvgIcon(String url) {
    return SvgPicture.asset(
      url,
      width: 24,
      height: 24,
      color: Colors.white,
      placeholderBuilder: (context) => CircularProgressIndicator(),
    );
  }

  Widget _buildNetworkImage(String url, {double? width, double? height}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Ошибка загрузки изображения: $error');
        return Icon(Icons.error, size: width ?? 50, color: Colors.red);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingIcons) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.black, size: 20),
                const SizedBox(width: 4),
                Text('Город',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            Icon(Icons.shopping_basket, color: AppColors.darkGreen),
          ],
        ),
      ),
      body: SingleChildScrollView(
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
                color: AppColors.veryLightGray,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(0, 4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
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
                  _buildNetworkImage(
                    'http://91.186.217.192/images/img_packandearth.png',
                    width: 100,
                  ),
                ],
              ),
            ),
            _buildSectionHeader('Ваши заказы', 'Все'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildNetworkImage(
                      'http://91.186.217.192/images/img_shopicon.png',
                      width: 100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('БулоШная',
                          style:
                              TextStyle(color: AppColors.white, fontSize: 20)),
                      const SizedBox(height: 4),
                      Text('сегодня, 19:00 – 21:00',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
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
                  backgroundColor: AppColors.lightGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {},
                child: Text('Больше предложений',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              ),
            ),
            _buildSectionHeader('Категории', 'Все'),
            Row(
              children: [
                _buildCategoryCard(
                    'Магазины', 'http://91.186.217.192/images/img_shop.png'),
                const SizedBox(width: 16),
                _buildCategoryCard('Рестораны',
                    'http://91.186.217.192/images/img_restoraunt.png'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: AppColors.lightGreen,
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(navIconsUrls.length, (index) {
              final isActive = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      navIconsUrls[index],
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
            }),
          ),
        ),
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
                foregroundColor: AppColors.accentGreen,
                textStyle: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imageUrl) {
    return Expanded(
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: AppColors.veryLightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
