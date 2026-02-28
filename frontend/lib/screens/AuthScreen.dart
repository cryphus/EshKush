import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/FrontendAuthService.dart';
import '../services/TelegramAuthService.dart';
import '../state/app_state.dart';
import 'RegistrationScreen.dart';
import 'dart:async';
import '../widgets/buttons/auth_button.dart';

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
      if (_isValidTelegramDeepLink(uri)) {
        await _telegramAuthService.handleDeepLink(context, uri.toString());
      }
    } catch (e) {
      // Ignore deep link errors silently
    }
  }

  bool _isValidTelegramDeepLink(Uri uri) {
    return uri.host == 'auth' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'telegram';
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
        // Сохраняем данные пользователя в AppState
        await AppState().loginWithData(
          name: result['username'] ?? result['displayName'] ?? 'Пользователь',
          email: result['email'],
          role: result['role'] ?? 'user',
          token: result['access_token'] ?? '',
        );
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _handleTelegramAuth() async {
    try {
      await _telegramAuthService.openTelegramBot();
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  void _handlePhoneAuth() {
    Navigator.of(context).pushNamed('/phone_auth');
  }

  void _handleVKAuth() {
    // VK OAuth — показываем заглушку
    _showErrorSnackbar('Вход через VK скоро будет доступен');
  }

  void _showErrorSnackbar(String message) {
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
      backgroundColor: const Color(0xFFFAF3E0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const _AuthTitle(),
              const _HeroImage(
                imageUrl: 'http://91.186.217.192/images/img_start.png',
              ),
              const Spacer(),
              _buildSocialAuthButtons(),
              const SizedBox(height: 30),
              _buildGuestButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialAuthButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AuthButton(
          iconPath: 'icons/google.svg',
          onPressed: _handleGoogleSignIn,
        ),
        AuthButton(
          iconPath: 'icons/vk.svg',
          onPressed: _handleVKAuth,
        ),
        AuthButton(
          iconPath: 'icons/phone.svg',
          onPressed: _handlePhoneAuth,
        ),
        AuthButton(
          iconPath: 'icons/telegram.svg',
          onPressed: _handleTelegramAuth,
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D9C65),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Войти как гость',
            style: TextStyle(
              fontFamily: 'stolzl',
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTitle extends StatelessWidget {
  const _AuthTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 90),
        Center(
          child: Text(
            'Еда с разумным выбором',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;

  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Padding(
          padding: const EdgeInsets.all(32),
          child: Icon(Icons.fastfood, size: 120, color: Colors.green.shade300),
        ),
      ),
    );
  }
}
