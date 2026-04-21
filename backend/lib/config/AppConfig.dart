import 'package:dotenv/dotenv.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

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
  
  // Redis configuration
  late final String redisHost;
  late final int redisPort;
  late final String redisPassword;
  late final int redisDb;
  late final Duration redisConnectionTimeout;

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
  String get vkRedirectUri     => '$oauthCallbackBaseUrl/auth/vk/callback';

  bool get isYandexConfigured => yandexClientId.isNotEmpty && yandexClientSecret.isNotEmpty;
  bool get isVkConfigured     => vkClientId.isNotEmpty && vkClientSecret.isNotEmpty;

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

  Future<void> initialize() async {
    final env = DotEnv(includePlatformEnvironment: true)..load();

    jwtSecret = env['JWT_SECRET'] ?? '';
    jwtRefreshSecret = env['JWT_REFRESH_SECRET'] ?? '';
    databaseUrl = env['DATABASE_URL'] ?? '';
    port = int.tryParse(env['PORT'] ?? '3000') ?? 3000;
    environment = env['ENVIRONMENT'] ?? 'development';
    
    allowedOrigins = (env['ALLOWED_ORIGINS'] ?? 'http://localhost:3000')
        .split(',')
        .map((e) => e.trim())
        .toList();
    
    rateLimitRequests = int.tryParse(env['RATE_LIMIT_REQUESTS'] ?? '100') ?? 100;
    rateLimitWindow = Duration(
      minutes: int.tryParse(env['RATE_LIMIT_WINDOW_MINUTES'] ?? '1') ?? 1
    );

    logLevel = (env['LOG_LEVEL'] ?? 'info').toLowerCase();
    logJson = (env['LOG_JSON'] ?? 'true').toLowerCase() == 'true';
    maxRequestBodyBytes = int.tryParse(env['MAX_REQUEST_BODY_BYTES'] ?? '10485760') ?? 10485760;
    
    // Redis configuration
    redisHost = env['REDIS_HOST'] ?? 'localhost';
    redisPort = int.tryParse(env['REDIS_PORT'] ?? '6379') ?? 6379;
    redisPassword = env['REDIS_PASSWORD'] ?? '';
    redisDb = int.tryParse(env['REDIS_DB'] ?? '0') ?? 0;
    redisConnectionTimeout = Duration(
      seconds: int.tryParse(env['REDIS_CONNECTION_TIMEOUT'] ?? '5') ?? 5
    );

    // OAuth — Yandex
    yandexClientId     = env['YANDEX_CLIENT_ID']     ?? '';
    yandexClientSecret = env['YANDEX_CLIENT_SECRET'] ?? '';

    // OAuth — VK
    vkClientId     = env['VK_CLIENT_ID']     ?? '';
    vkClientSecret = env['VK_CLIENT_SECRET'] ?? '';

    // OAuth — URLs
    oauthCallbackBaseUrl = env['OAUTH_CALLBACK_BASE_URL'] ?? 'http://localhost:8080';
    frontendUrl          = env['FRONTEND_URL']            ?? 'http://localhost:3000';

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

    _validateConfig();
  }

  void _validateConfig() {
    if (jwtSecret.isEmpty) {
      throw Exception('JWT_SECRET не установлен в переменных окружения');
    }
    if (jwtSecret.length < 32) {
      throw Exception('JWT_SECRET должен быть не менее 32 символов');
    }
    if (jwtRefreshSecret.isEmpty) {
      throw Exception('JWT_REFRESH_SECRET не установлен в переменных окружения');
    }
    if (jwtRefreshSecret.length < 32) {
      throw Exception('JWT_REFRESH_SECRET должен быть не менее 32 символов');
    }
    if (databaseUrl.isEmpty) {
      throw Exception('DATABASE_URL не установлен в переменных окружения');
    }
    if (port <= 0 || port > 65535) {
      throw Exception('PORT должен быть от 1 до 65535');
    }
    if (rateLimitRequests <= 0) {
      throw Exception('RATE_LIMIT_REQUESTS должен быть > 0');
    }
    if (allowedOrigins.isEmpty) {
      throw Exception('ALLOWED_ORIGINS не может быть пустым');
    }
    if (isProduction && allowedOrigins.contains('*')) {
      throw Exception('ALLOWED_ORIGINS не может содержать * в production');
    }
    if (isProduction && redisPassword.isEmpty) {
      throw Exception('REDIS_PASSWORD должен быть задан в production');
    }
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';
} 