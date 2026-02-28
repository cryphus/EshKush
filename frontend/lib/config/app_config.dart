/// Конфигурация приложения.
///
/// Значения вшиваются на этапе сборки через `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080 ...
///
/// Для удобства используй скрипты в scripts/:
///   scripts/run_test.sh   — запуск в режиме разработки
///   scripts/build_prod.sh — сборка web для продакшна
class AppConfig {
  AppConfig._();

  // ── Backend ────────────────────────────────────────────────────────────────

  /// URL основного Dart Shelf backend (без trailing slash).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // ── Telegram Auth Service ──────────────────────────────────────────────────

  /// URL Flask-сервиса Telegram-бота (без trailing slash).
  static const String telegramApiUrl = String.fromEnvironment(
    'TELEGRAM_API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // ── Google OAuth ───────────────────────────────────────────────────────────

  /// Google OAuth 2.0 Client ID.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // ── Telegram Bot ───────────────────────────────────────────────────────────

  /// Username бота (без @).
  static const String botUsername = String.fromEnvironment(
    'BOT_USERNAME',
    defaultValue: 'eshkush_bot',
  );

  // ── Медиа ──────────────────────────────────────────────────────────────────

  /// Базовый URL сервера изображений (без trailing slash).
  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    defaultValue: 'http://91.186.217.192',
  );
}
