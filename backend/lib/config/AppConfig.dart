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
  
  // Redis configuration
  late final String redisHost;
  late final int redisPort;
  late final String redisPassword;
  late final int redisDb;
  late final Duration redisConnectionTimeout;

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
    
    // Redis configuration
    redisHost = env['REDIS_HOST'] ?? 'localhost';
    redisPort = int.tryParse(env['REDIS_PORT'] ?? '6379') ?? 6379;
    redisPassword = env['REDIS_PASSWORD'] ?? '';
    redisDb = int.tryParse(env['REDIS_DB'] ?? '0') ?? 0;
    redisConnectionTimeout = Duration(
      seconds: int.tryParse(env['REDIS_CONNECTION_TIMEOUT'] ?? '5') ?? 5
    );

    _validateConfig();
  }

  void _validateConfig() {
    if (jwtSecret.isEmpty) {
      throw Exception('JWT_SECRET не установлен в переменных окружения');
    }
    if (jwtRefreshSecret.isEmpty) {
      throw Exception('JWT_REFRESH_SECRET не установлен в переменных окружения');
    }
    if (databaseUrl.isEmpty) {
      throw Exception('DATABASE_URL не установлен в переменных окружения');
    }
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';
} 