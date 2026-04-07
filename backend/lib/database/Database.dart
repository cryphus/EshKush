import 'dart:io';
import 'package:postgres/postgres.dart';

import '../utils/LoggingUtils.dart';

class Database {
  static Database? _instance;
  late PostgreSQLConnection _connection;

  Database._();

  static Future<Database> get instance async {
    _instance ??= await _init();
    return _instance!;
  }

  static Future<Database> _init() async {
    final db = Database._();
    final env = Platform.environment;

    await LoggingUtils.logInfo(
      'Подключение к базе данных',
      context: {
        'host': env['DB_HOST'] ?? 'localhost',
        'port': env['DB_PORT'] ?? '5432',
        'database': env['DB_NAME'] ?? 'flutter_auth',
        'user': env['DB_USER'] ?? 'postgres',
      },
    );

    final dbPassword = env['DB_PASSWORD'];
    final isProd = (env['ENVIRONMENT'] ?? 'development') == 'production';
    if (dbPassword == null || dbPassword.isEmpty) {
      if (isProd) {
        await LoggingUtils.logError(
          'DB_PASSWORD не задан — запуск в production без пароля БД запрещён',
          'ConfigError',
          requestId: null,
        );
        exit(1);
      }
      await LoggingUtils.logInfo(
        'DB_PASSWORD не задан, используется пустой пароль (только для dev)',
      );
    }

    db._connection = PostgreSQLConnection(
      env['DB_HOST'] ?? 'localhost',
      int.parse(env['DB_PORT'] ?? '5432'),
      env['DB_NAME'] ?? 'flutter_auth',
      username: env['DB_USER'] ?? 'postgres',
      password: dbPassword ?? '',
      timeoutInSeconds: 30,
      useSSL: false,
    );

    try {
      await db._connection.open();
      await db._connection.execute('SET client_encoding TO \'UTF8\'');
      await LoggingUtils.logInfo('Подключение к базе данных успешно установлено');
    } catch (e, stackTrace) {
      await LoggingUtils.logError(
        'Ошибка подключения к базе данных',
        e,
        requestId: null,
        stackTrace: stackTrace,
      );
      exit(1);
    }
    return db;
  }

  PostgreSQLConnection get connection => _connection;
} 
