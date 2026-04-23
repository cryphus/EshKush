import 'dart:io';
import 'package:postgres/postgres.dart';

/// Вспомогательный класс для интеграционных тестов репозиториев.
///
/// Подключается к тестовой БД (отдельный контейнер postgres-test).
/// Переменные окружения (задаются в docker-compose, сервис repo-tests):
///   TEST_DB_HOST, TEST_DB_PORT, TEST_DB_NAME, TEST_DB_USER, TEST_DB_PASSWORD
///
/// Использование в тестах:
///   setUpAll(() async { conn = await TestDb.connect(); repo = MyRepo(conn); });
///   setUp(()   async { await TestDb.truncate(conn, ['my_table']); });
///   tearDownAll(() async => TestDb.close());
class TestDb {
  static PostgreSQLConnection? _connection;

  static Future<PostgreSQLConnection> connect() async {
    if (_connection != null && !_connection!.isClosed) return _connection!;

    _connection = PostgreSQLConnection(
      Platform.environment['TEST_DB_HOST'] ?? 'localhost',
      int.tryParse(Platform.environment['TEST_DB_PORT'] ?? '') ?? 5435,
      Platform.environment['TEST_DB_NAME'] ?? 'eshkush_test',
      username: Platform.environment['TEST_DB_USER'] ?? 'postgres',
      password: Platform.environment['TEST_DB_PASSWORD'] ?? 'postgres',
    );
    await _connection!.open();
    return _connection!;
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  /// Очищает таблицы и сбрасывает sequence (SERIAL/BIGSERIAL) к 1.
  /// Порядок важен — сначала дочерние таблицы (FK ссылаются на родительские).
  static Future<void> truncate(
    PostgreSQLConnection conn,
    List<String> tables,
  ) async {
    final joined = tables.join(', ');
    await conn.execute('TRUNCATE $joined RESTART IDENTITY CASCADE');
  }

  /// Проверяет, доступна ли тестовая БД (для условного skip).
  static bool get isAvailable =>
      Platform.environment.containsKey('TEST_DB_HOST');
}