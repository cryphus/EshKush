import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eshkush/screens/MainScreen.dart';
import 'package:eshkush/screens/ProductPage.dart';
import 'package:eshkush/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'providers/auth_provider.dart';
import 'screens/AuthScreen.dart';
import 'screens/SimpleRegisterScreen.dart';
import 'state/app_state.dart';
import 'utils/snackbar.dart';
import 'utils/web_url_cleanup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Обрабатываем OAuth callback: бэкенд редиректит на /?access_token=...&refresh_token=...
  if (kIsWeb) {
    final uri = Uri.base;
    var fragmentParams = <String, String>{};
    if (uri.fragment.isNotEmpty) {
      try {
        fragmentParams = Uri.splitQueryString(uri.fragment);
      } catch (_) {
        fragmentParams = <String, String>{};
      }
    }
    final oauthToken =
        uri.queryParameters['access_token'] ?? fragmentParams['access_token'];
    final oauthRefresh =
        uri.queryParameters['refresh_token'] ?? fragmentParams['refresh_token'];
    final oauthError =
        uri.queryParameters['oauth_error'] ?? fragmentParams['oauth_error'];
    if (oauthToken != null && oauthToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', oauthToken);
      if (oauthRefresh != null && oauthRefresh.isNotEmpty) {
        await prefs.setString('refresh_token', oauthRefresh);
      }
    }
    if (oauthToken != null || oauthRefresh != null || oauthError != null) {
      cleanupOAuthParamsFromUrl();
    }
  }

  await AppState().initialize();

  if (!kIsWeb) {
    AndroidYandexMap.useAndroidViewSurface = false;
  }

  final container = ProviderContainer();
  await container.read(authProvider.notifier).loadSavedAuth();

  runApp(
      UncontrolledProviderScope(container: container, child: const EshKush()));
}

class EshKush extends ConsumerWidget {
  const EshKush({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    final isSignedIn = auth.accessToken != null;

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
      initialRoute: '/',
      routes: {
        '/': (context) => isSignedIn ? const MainScreen() : const AuthScreen(),
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
        '/register': (context) => const SimpleRegisterScreen(),
        '/product': (context) => ProductPage(
              data: ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>,
            ),
      },
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => isSignedIn ? const MainScreen() : const AuthScreen(),
      ),
    );
  }
}
