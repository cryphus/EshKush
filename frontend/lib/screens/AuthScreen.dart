import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../theme/colors.dart';
import 'LoginPasswordScreen.dart';
import 'SimpleRegisterScreen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<void> _openOAuth(BuildContext context, String provider) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/$provider');
    final launched = await launchUrl(url, webOnlyWindowName: '_self');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть $provider OAuth'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
              Expanded(
                child: Center(
                  child: Image.network(
                    'http://91.186.217.192/images/img_start.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag,
                      size: 120,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Социальные кнопки: Яндекс и ВК
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    iconPath: 'assets/icons/yandex.svg',
                    label: 'Яндекс',
                    onTap: () => _openOAuth(context, 'yandex'),
                  ),
                  const SizedBox(width: 20),
                  _SocialButton(
                    iconPath: 'assets/icons/vk.svg',
                    label: 'ВКонтакте',
                    onTap: () => _openOAuth(context, 'vk'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Кнопка "Войти" (логин/телефон + пароль)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPasswordScreen()),
                  ),
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
                    'Войти',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Кнопка "Зарегистрироваться"
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SimpleRegisterScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Войти как гость
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
                child: const Text(
                  'Войти как гость',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String? iconPath;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: iconPath != null
                  ? SvgPicture.asset(
                      iconPath!,
                      width: 36,
                      height: 36,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accentGreen,
                        BlendMode.srcIn,
                      ),
                    )
                  : const Icon(Icons.login, size: 36, color: AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
