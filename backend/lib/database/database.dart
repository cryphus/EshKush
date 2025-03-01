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

    db._connection = PostgreSQLConnection(
      env['DB_HOST'] ?? 'localhost',
      int.parse(env['DB_PORT'] ?? '5432'),
      env['DB_NAME'] ?? 'flutter_auth',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASSWORD'] ?? 'TQr132123',
    );

    await db._connection.open();
    return db;
  }

  PostgreSQLConnection get connection => _connection;
} 