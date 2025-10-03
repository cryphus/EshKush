import 'dart:io';
import 'package:postgres/postgres.dart';


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

    print('Подключение к базе данных...');
    print('Host: ${env['DB_HOST'] ?? 'localhost'}');
    print('Port: ${env['DB_PORT'] ?? '5432'}');
    print('Database: ${env['DB_NAME'] ?? 'flutter_auth'}');
    print('User: ${env['DB_USER'] ?? 'postgres'}');

    db._connection = PostgreSQLConnection(
      env['DB_HOST'] ?? 'localhost',
      int.parse(env['DB_PORT'] ?? '5432'),
      env['DB_NAME'] ?? 'flutter_auth',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASSWORD'] ?? 'TQr132123',
      timeoutInSeconds: 30,
      useSSL: false,
    );

    try {
      await db._connection.open();
      await db._connection.execute('SET client_encoding TO \'UTF8\'');
      print('Подключение к базе данных успешно установлено');
    } catch (e) {
      print('Ошибка подключения к базе данных: $e');
      rethrow;
    }
    return db;
  }

  PostgreSQLConnection get connection => _connection;
} 
