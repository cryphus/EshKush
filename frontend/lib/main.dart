import 'package:flutter/material.dart';
import 'package:eshkush/screens/MainScreen.dart';
import 'package:eshkush/screens/ProductPage.dart';
import 'package:eshkush/screens/PhoneAuthScreen.dart';
import 'package:eshkush/screens/partner/PartnerScreen.dart';
import 'package:eshkush/theme/colors.dart';
import 'package:eshkush/state/app_state.dart';
import 'screens/AuthScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize();
  runApp(const EshKush());
}

class EshKush extends StatelessWidget {
  const EshKush({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = AppState().accessToken != null ? '/main' : '/auth';

    return MaterialApp(
      title: 'EshKush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'stolzl',
        textTheme: ThemeData.light().textTheme.copyWith(
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
        scaffoldBackgroundColor: AppColors.colorBackground,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
        '/phone_auth': (context) => const PhoneAuthScreen(),
        '/partner': (context) => const PartnerScreen(),
        '/product': (context) => ProductPage(
              data: ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>,
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('eshkush://auth/telegram') ?? false) {
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
