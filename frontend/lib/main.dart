import 'package:flutter/material.dart';
import 'package:eshkush/screens/MainScreen.dart';
import 'package:eshkush/screens/ProductPage.dart';
import 'package:eshkush/screens/PhoneLoginScreen.dart';
import 'package:eshkush/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'screens/AuthScreen.dart';
import 'utils/snackbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yandex MapKit: сам API-ключ задаётся в нативных файлах
  // (AndroidManifest.xml meta-data com.yandex.maps.MAPKIT_API_KEY и
  // iOS Info.plist YandexMapkitApiKey). Здесь мы только отключаем
  // отрисовку через Android View Surface (по рекомендации плагина).
  // См. memory: project/map_provider_yandex (yandex_mapkit, free tier).
  AndroidYandexMap.useAndroidViewSurface = false;

  runApp(const ProviderScope(child: EshKush()));
}

class EshKush extends StatelessWidget {
  const EshKush({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = AppState().accessToken != null ? '/main' : '/auth';

    return MaterialApp(
      title: 'EshKush',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'stolzl',
        textTheme: ThemeData.light().textTheme.copyWith(
              headlineMedium: const TextStyle(
                fontSize: 28,
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
        '/phone-login': (context) => const PhoneLoginScreen(),
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
