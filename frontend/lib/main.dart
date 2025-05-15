import 'package:eshkush/screens/MainScreen.dart';
import 'package:eshkush/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/RegistrationScreen.dart';
import 'screens/AuthScreen.dart';

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
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme.copyWith(
                headlineMedium: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                bodyLarge: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
        ),
        scaffoldBackgroundColor: AppColors.colorBackground,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
        // '/registration': (context) => const RegistrationScreen(),
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
