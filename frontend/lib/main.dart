import 'package:eshkush/screens/FavoritesScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/HomeScreen.dart';
import 'screens/OffersScreen.dart';
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
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/offers': (context) => const OffersPage(),
        '/favorites': (context) => const FavoritesPage(),
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
