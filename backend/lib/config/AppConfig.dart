import 'package:dotenv/dotenv.dart';
import '../utils/AppException.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static bool _initialized = false;

  late final String jwtSecret;
  late final String jwtRefreshSecret;
  late final String databaseUrl;
  late final int port;
  late final String environment;
  late final List<String> allowedOrigins;
  late final int rateLimitRequests;
  late final Duration rateLimitWindow;
  late final String logLevel; // debug|info|warn|error
  late final bool logJson;
  late final int maxRequestBodyBytes;
  late final bool trustProxyHeaders;
  late final List<String> trustedProxyIps;

  // Redis configuration
  late String redisHost;
  late int redisPort;
  late String redisPassword;
  late int redisDb;
  late Duration redisConnectionTimeout;

  // OAuth — Yandex
  late final String yandexClientId;
  late final String yandexClientSecret;

  // OAuth — VK
  late final String vkClientId;
  late final String vkClientSecret;

  // OAuth — URLs
  late final String oauthCallbackBaseUrl;
  late final String frontendUrl;

  String get yandexRedirectUri => '$oauthCallbackBaseUrl/auth/yandex/callback';
  String get vkRedirectUri => '$oauthCallbackBaseUrl/auth/vk/callback';

  bool get isYandexConfigured =>
      yandexClientId.isNotEmpty && yandexClientSecret.isNotEmpty;
  bool get isVkConfigured => vkClientId.isNotEmpty && vkClientSecret.isNotEmpty;

  // YooKassa configuration
  late final String yookassaShopId;
  late final String yookassaSecretKey;
  late final String yookassaApiBaseUrl;
  late final String yookassaReturnUrl;
  late final String yookassaWebhookSecret;
  bool get isYookassaConfigured =>
      yookassaShopId.isNotEmpty && yookassaSecretKey.isNotEmpty;

  /// Сколько часов после создания заказа можно вернуть деньги.
  late final Duration refundWindow;

  /// Интервал периодической очистки истёкших сессий.
  late final Duration sessionCleanupInterval;

  Future<void> initialize() async {
    if (_initialized) return;
    final env = DotEnv(includePlatformEnvironment: true)..load();

    jwtSecret = env['JWT_SECRET'] ?? '';
    jwtRefreshSecret = env['JWT_REFRESH_SECRET'] ?? '';
    final rawDatabaseUrl = env['DATABASE_URL'] ?? '';
    databaseUrl =
        rawDatabaseUrl.isNotEmpty ? rawDatabaseUrl : _buildDatabaseUrl(env);
    port = int.tryParse(env['PORT'] ?? '3000') ?? 3000;
    environment = env['ENVIRONMENT'] ?? 'development';

    allowedOrigins = (env['ALLOWED_ORIGINS'] ?? 'http://localhost:3000')
        .split(',')
        .map((e) => e.trim())
        .toList();

    rateLimitRequests =
        int.tryParse(env['RATE_LIMIT_REQUESTS'] ?? '100') ?? 100;
    rateLimitWindow = Duration(
        minutes: int.tryParse(env['RATE_LIMIT_WINDOW_MINUTES'] ?? '1') ?? 1);

    logLevel = (env['LOG_LEVEL'] ?? 'info').toLowerCase();
    logJson = (env['LOG_JSON'] ?? 'true').toLowerCase() == 'true';
    maxRequestBodyBytes =
        int.tryParse(env['MAX_REQUEST_BODY_BYTES'] ?? '10485760') ?? 10485760;
    trustProxyHeaders =
        (env['TRUST_PROXY_HEADERS'] ?? (isProduction ? 'false' : 'true'))
                .toLowerCase() ==
            'true';
    trustedProxyIps = (env['TRUSTED_PROXY_IPS'] ?? '127.0.0.1,::1')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Redis configuration
    redisHost = env['REDIS_HOST'] ?? 'localhost';
    redisPort = int.tryParse(env['REDIS_PORT'] ?? '6379') ?? 6379;
    redisPassword = env['REDIS_PASSWORD'] ?? '';
    redisDb = int.tryParse(env['REDIS_DB'] ?? '0') ?? 0;
    redisConnectionTimeout = Duration(
        seconds: int.tryParse(env['REDIS_CONNECTION_TIMEOUT'] ?? '5') ?? 5);

    // OAuth — Yandex
    yandexClientId = env['YANDEX_CLIENT_ID'] ?? '';
    yandexClientSecret = env['YANDEX_CLIENT_SECRET'] ?? '';

    // OAuth — VK
    vkClientId = env['VK_CLIENT_ID'] ?? '';
    vkClientSecret = env['VK_CLIENT_SECRET'] ?? '';

    // OAuth — URLs
    oauthCallbackBaseUrl =
        env['OAUTH_CALLBACK_BASE_URL'] ?? 'http://localhost:3000';
    frontendUrl = env['FRONTEND_URL'] ?? 'http://localhost:3000';

    // YooKassa configuration
    yookassaShopId = env['YOOKASSA_SHOP_ID'] ?? '';
    yookassaSecretKey = env['YOOKASSA_SECRET_KEY'] ?? '';
    yookassaApiBaseUrl =
        env['YOOKASSA_API_BASE_URL'] ?? 'https://api.yookassa.ru/v3';
    yookassaReturnUrl =
        env['YOOKASSA_RETURN_URL'] ?? 'https://eshkush.app/payments/return';
    yookassaWebhookSecret = env['YOOKASSA_WEBHOOK_SECRET'] ?? '';

    refundWindow = Duration(
      hours: int.tryParse(env['REFUND_WINDOW_HOURS'] ?? '24') ?? 24,
    );

    sessionCleanupInterval = Duration(
      minutes:
          int.tryParse(env['SESSION_CLEANUP_INTERVAL_MINUTES'] ?? '15') ?? 15,
    );

    _validateConfig();
    _initialized = true;
  }

  /// Инициализирует конфигурацию значениями по умолчанию для юнит-тестов.
  /// Безопасно вызывать несколько раз — повторные вызовы игнорируются.
  static void initForTesting() {
    if (_initialized) return;
    _instance.jwtSecret = 'testsecretforjwttestingatleast32chars';
    _instance.jwtRefreshSecret = 'testrefreshsecretforjwttests32chars__';
    _instance.databaseUrl = 'postgres://test:test@localhost/test';
    _instance.port = 3000;
    _instance.environment = 'test';
    _instance.allowedOrigins = ['http://localhost:3000'];
    _instance.rateLimitRequests = 100;
    _instance.rateLimitWindow = const Duration(minutes: 1);
    _instance.logLevel = 'error'; // подавляем логи в тестах
    _instance.logJson = false;
    _instance.redisHost = 'localhost';
    _instance.redisPort = 6379;
    _instance.redisPassword = '';
    _instance.redisDb = 0;
    _instance.redisConnectionTimeout = const Duration(seconds: 5);
    _instance.maxRequestBodyBytes = 10485760;
    _instance.trustProxyHeaders = true;
    _instance.trustedProxyIps = ['127.0.0.1', '::1'];
    _instance.yandexClientId = '';
    _instance.yandexClientSecret = '';
    _instance.vkClientId = '';
    _instance.vkClientSecret = '';
    _instance.oauthCallbackBaseUrl = 'http://localhost:3000';
    _instance.frontendUrl = 'http://localhost:3000';
    _instance.yookassaShopId = '';
    _instance.yookassaSecretKey = '';
    _instance.yookassaApiBaseUrl = 'https://api.yookassa.ru/v3';
    _instance.yookassaReturnUrl = 'https://eshkush.app/payments/return';
    _instance.yookassaWebhookSecret = '';
    _instance.refundWindow = const Duration(hours: 24);
    _instance.sessionCleanupInterval = const Duration(minutes: 15);
    _initialized = true;
  }

  void _validateConfig() {
    if (jwtSecret.isEmpty) {
      throw InternalServerException(
          'JWT_SECRET не установлен в переменных окружения');
    }
    if (jwtSecret.length < 32) {
      throw InternalServerException(
          'JWT_SECRET должен быть не менее 32 символов');
    }
    if (jwtRefreshSecret.isEmpty) {
      throw InternalServerException(
          'JWT_REFRESH_SECRET не установлен в переменных окружения');
    }
    if (jwtRefreshSecret.length < 32) {
      throw InternalServerException(
          'JWT_REFRESH_SECRET должен быть не менее 32 символов');
    }
    if (databaseUrl.isEmpty) {
      throw InternalServerException(
          'DATABASE_URL не установлен в переменных окружения');
    }
    if (port <= 0 || port > 65535) {
      throw InternalServerException('PORT должен быть от 1 до 65535');
    }
    if (rateLimitRequests <= 0) {
      throw InternalServerException('RATE_LIMIT_REQUESTS должен быть > 0');
    }
    if (allowedOrigins.isEmpty) {
      throw InternalServerException('ALLOWED_ORIGINS не может быть пустым');
    }
    if (isProduction && allowedOrigins.contains('*')) {
      throw InternalServerException(
          'ALLOWED_ORIGINS не может содержать * в production');
    }
    if (isProduction && redisPassword.isEmpty) {
      throw InternalServerException(
          'REDIS_PASSWORD должен быть задан в production');
    }
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';

  static String _buildDatabaseUrl(dynamic env) {
    final host = env['DB_HOST'] ?? 'localhost';
    final port = env['DB_PORT'] ?? '5432';
    final name = env['DB_NAME'] ?? 'flutter_auth';
    final user = env['DB_USER'] ?? 'postgres';
    final pass = env['DB_PASSWORD'] ?? '';
    return 'postgresql://$user:$pass@$host:$port/$name';
  }
}
