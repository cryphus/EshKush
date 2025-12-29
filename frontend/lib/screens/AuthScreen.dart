import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/FrontendAuthService.dart';
import '../services/TelegramAuthService.dart';
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
      print('Deep link check error: $e');
    }
  }

  bool _isValidTelegramDeepLink(Uri uri) {
    return uri.scheme == 'eshkush' &&
        uri.host == 'auth' &&
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
        Navigator.of(context).pushReplacementNamed('/home');
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

  void _showErrorSnackbar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $message')),
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
              const _NetworkImageWidget(
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
          onPressed: () {},
        ),
        AuthButton(
          iconPath: 'icons/phone.svg',
          onPressed: () {},
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
        child: _GuestButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
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

class _NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double widthPercentage;

  const _NetworkImageWidget({
    required this.imageUrl,
    this.widthPercentage = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * widthPercentage,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      ),
    );
  }
}

class _GuestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GuestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6D9C65),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(0, 30),
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
    );
  }
}
