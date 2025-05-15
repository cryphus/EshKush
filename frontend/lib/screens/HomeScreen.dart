import 'package:flutter/material.dart';
import '../services/FrontendAuthService.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../screens/OffersScreen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _authService = FrontendAuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppColors.colorBackground,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  Widget _buildNetworkImage(String url, {double? width}) => Image.network(
        url,
        width: width,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _buildLoadingIndicator(progress),
        errorBuilder: (context, error, _) => Icon(
          Icons.error,
          size: width ?? 50,
          color: Colors.red,
        ),
      );

  Widget _buildLoadingIndicator(ImageChunkEvent progress) => Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _buildBodyContent();
  }

  Widget _buildBodyContent() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserGreetingCard(),
            const SizedBox(height: 24),
            _buildOrdersSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
          ],
        ),
      );

  Widget _buildUserGreetingCard() => Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.veryLightGray,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Привет,', style: _greetingTextStyle),
                  Text('Гость', style: _greetingTextStyle),
                  const SizedBox(height: 8),
                  const Text('Только в этом месяце ты сохранил 2 кг еды!'),
                ],
              ),
            ),
            _buildNetworkImage(
              'http://91.186.217.192/images/img_packandearth.png',
              width: 100,
            ),
          ],
        ),
      );

  TextStyle get _greetingTextStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
      );

  Widget _buildOrdersSection() => Column(
        children: [
          _SectionHeader(
            title: 'Ваши заказы',
            actionText: 'Все',
            onActionPressed: () {},
          ),
          _buildOrderCard(),
          const SizedBox(height: 16),
          _buildMoreOffersButton(),
        ],
      );

  Widget _buildOrderCard() => Container(
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
                Text('БулоШная', style: _shopNameStyle),
                const SizedBox(height: 4),
                Text('сегодня, 19:00 – 21:00', style: _shopScheduleStyle),
              ],
            ),
          ],
        ),
      );

  TextStyle get _shopNameStyle => const TextStyle(
        color: AppColors.white,
        fontSize: 20,
      );

  TextStyle get _shopScheduleStyle => const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      );

  Widget _buildMoreOffersButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGreen,
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OffersPage()),
            );
          },
          child: const Text(
            'Больше предложений',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
      );

  Widget _buildCategoriesSection() => Column(
        children: [
          _SectionHeader(
            title: 'Категории',
            actionText: 'Все',
            onActionPressed: () {},
          ),
          const Row(
            children: [
              _CategoryCard(
                title: 'Магазины',
                imageUrl: 'http://91.186.217.192/images/img_shop.png',
              ),
              const SizedBox(width: 16),
              _CategoryCard(
                title: 'Рестораны',
                imageUrl: 'http://91.186.217.192/images/img_restoraunt.png',
              ),
            ],
          ),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          TextButton(
            onPressed: onActionPressed,
            child: Text(actionText),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentGreen,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _CategoryCard({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
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
