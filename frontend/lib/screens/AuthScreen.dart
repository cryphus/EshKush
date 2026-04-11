import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/FrontendAuthService.dart';
import '../services/TelegramAuthService.dart';
import '../theme/colors.dart';
import 'PhoneLoginScreen.dart';
import 'RegistrationScreen.dart';
import 'dart:async';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FrontendAuthService authService = FrontendAuthService();
  final TelegramAuthService _telegramAuthService = TelegramAuthService();
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _startDeepLinkChecking();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startDeepLinkChecking() {
    _checkDeepLink();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkDeepLink(),
    );
  }

  Future<void> _checkDeepLink() async {
    try {
      final uri = Uri.base;
      if (uri.scheme == 'eshkush' &&
          uri.host == 'auth' &&
          uri.pathSegments.isNotEmpty &&
          uri.pathSegments[0] == 'telegram') {
        await _telegramAuthService.handleDeepLink(context, uri.toString());
      }
    } catch (e) {
      debugPrint('Deep link check error: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final result = await authService.signInWithGoogle();
      if (result == null || !context.mounted) return;

      if (result['needsRegistration'] == true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistrationScreen(
              email: result['email'] ?? '',
              displayName: result['displayName'] ?? '',
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _handleTelegramAuth() async {
    try {
      await _telegramAuthService.openTelegramBot();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _handlePhoneLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $message'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Заголовок
              const Text(
                'Еда с разумным\nвыбором',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              // Изображение пакета с продуктами
              Expanded(
                child: Center(
                  child: Image.network(
                    'http://91.186.217.192/images/img_start.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.shopping_bag, size: 120, color: AppColors.accentGreen),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Кнопки авторизации (Google, VK, Телефон)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    iconPath: 'assets/icons/google.svg',
                    onTap: _handleGoogleSignIn,
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    iconPath: 'assets/icons/vk.svg',
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    iconPath: 'assets/icons/phone.svg',
                    onTap: _handlePhoneLogin,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Кнопка "Войти как гость"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Войти как гость',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;

  const _SocialButton({required this.iconPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentGreen, width: 1.5),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(AppColors.accentGreen, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
