import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/HomeScreen.dart';
import 'screens/RegistrationScreen.dart';
import 'services/FrontendAuthService.dart';

void main() {
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
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade200,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'EshKush',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAuthButton(
                    context,
                    '',
                    'assets/icons/google.svg',
                    () async {
                      final authService = FrontendAuthService();
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
                  const SizedBox(width: 20),
                  _buildAuthButton(
                    context,
                    '',
                    'assets/icons/vk.svg',
                    () {
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildAuthButton(
                    context,
                    '',
                    'assets/icons/phone.svg',
                    () {
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Войти как гость',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, String text, String iconPath, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
          ),
        ),
      ),
    );
  }
}
