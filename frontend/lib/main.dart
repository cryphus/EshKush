import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/HomeScreen.dart';
import 'screens/RegistrationScreen.dart';
import 'services/FrontendAuthService.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/TelegramAuthService.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EshKush());
}

class EshKush extends StatelessWidget {
  const EshKush({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EshKush',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('tg://eshkush/auth/telegram') ?? false) {
          return MaterialPageRoute(
            builder: (context) => const AuthScreen(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final authService = FrontendAuthService();
  final TelegramAuthService _telegramAuthService = TelegramAuthService();
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkDeepLink();
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkDeepLink());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _checkDeepLink() async {
    try {
      final uri = Uri.base;
      if (uri.scheme == 'eshkush' && uri.host == 'auth' && uri.pathSegments[0] == 'telegram') {
        await _telegramAuthService.handleDeepLink(context, uri.toString());
      }
    } catch (e) {
      print('Ошибка при проверке deep link: $e');
    }
  }

  void _handleTelegramAuth() async {
    try {
      await _telegramAuthService.openTelegramBot();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
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
              const SizedBox(height: 90),
              const Center(
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
              const SizedBox(height: 50),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Image.network(
                  'http://localhost:5000/images/img_start.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAuthButton(
                    context,
                    'assets/icons/google.svg',
                    () async {
                      try {
                        final result = await authService.signInWithGoogle();
                        if (result != null && context.mounted) {
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
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    },
                  ),
                  _buildAuthButton(
                    context,
                    'assets/icons/vk.svg',
                    () {
                    },
                  ),
                  _buildAuthButton(
                    context,
                    'assets/icons/phone.svg',
                    () {
                    },
                  ),
                  _buildAuthButton(
                    context,
                    'assets/icons/telegram.svg',
                    _handleTelegramAuth,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
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

  Widget _buildAuthButton(
    BuildContext context,
    String iconPath,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: SvgPicture.asset(
          iconPath,
          width: 60,
          height: 60,
          color: const Color(0xFF91CA6D),
        ),
      ),
    );
  }
}
