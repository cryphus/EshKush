import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eshkush/screens/main_screen.dart';
import 'package:eshkush/screens/product_page.dart';
import 'package:eshkush/screens/product_detail_screen.dart';
import 'package:eshkush/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/simple_register_screen.dart';
import 'state/app_state.dart';
import 'utils/snackbar.dart';
import 'utils/web_url_cleanup.dart';

/// Данные из Telegram-бота для пользователя, которого ещё нет в системе —
/// заполняются в main() из deep link `?data=...` и один раз потребляются
/// маршрутом `/`, чтобы показать RegistrationScreen с предзаполненными полями.
class PendingTelegramRegistration {
  static Map<String, dynamic>? data;
}

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

    // Обрабатываем возврат из Telegram-бота: бэкенд(telegramAuth) редиректит
    // на /auth/telegram?data=<base64url JSON>. Если пользователь уже
    // существует — data содержит accessToken/refreshToken (вход без пароля).
    // Если нет — данные телефона/имени сохраняются для экрана регистрации.
    final telegramDataRaw = uri.queryParameters['data'] ?? fragmentParams['data'];
    if (telegramDataRaw != null && telegramDataRaw.isNotEmpty) {
      try {
        final decoded = utf8.decode(base64Url.decode(base64Url.normalize(telegramDataRaw)));
        final telegramData = jsonDecode(decoded) as Map<String, dynamic>;
        final exists = telegramData['exists'] == true;
        final accessToken = telegramData['accessToken']?.toString();
        if (exists && accessToken != null && accessToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          final refreshToken = telegramData['refreshToken']?.toString();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await prefs.setString('refresh_token', refreshToken);
          }
        } else if (!exists) {
          PendingTelegramRegistration.data = telegramData;
        }
      } catch (_) {
        // Повреждённые/устаревшие данные диплинка — просто игнорируем.
      }
      cleanupOAuthParamsFromUrl();
    }
  }

  await AppState().initialize();

  final container = ProviderContainer();
  await container.read(authProvider.notifier).loadSavedAuth();

  runApp(
      UncontrolledProviderScope(container: container, child: const EshKush()));
}

class EshKush extends ConsumerWidget {
  const EshKush({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isSignedIn = auth.accessToken != null;

    ref.listen(cartProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        showSnack(next.error!, kind: SnackKind.error);
      }
    });

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
        '/': (context) {
          final pending = PendingTelegramRegistration.data;
          if (pending != null) {
            PendingTelegramRegistration.data = null;
            final firstName = pending['firstName']?.toString() ?? '';
            final lastName = pending['lastName']?.toString() ?? '';
            return RegistrationScreen(
              email: '',
              displayName: '$firstName $lastName'.trim(),
              phoneNumber: pending['phoneNumber']?.toString(),
              isFromTelegram: true,
            );
          }
          return isSignedIn ? const MainScreen() : const AuthScreen();
        },
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
        '/register': (context) => const SimpleRegisterScreen(),
        '/product': (context) => ProductPage(
              data: ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/product-detail': (context) => ProductDetailScreen(
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
