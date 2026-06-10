/// Инструмент применения SQL-миграций.
///
/// Использование:
///   dart run bin/Migrate.dart
///
/// Переменные окружения (те же что у сервера):
///   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
///
/// Что делает:
///   1. Подключается к БД
///   2. Создаёт таблицу schema_migrations (если её нет)
///   3. Читает файлы из database/migrations/*.sql в алфавитном порядке
///   4. Применяет только те, которых нет в schema_migrations
///   5. Каждую миграцию оборачивает в транзакцию
import 'dart:io';
import 'package:postgres/postgres.dart';

Future<void> main() async {
  final env = Platform.environment;

  final host = env['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
  final database = env['DB_NAME'] ?? 'flutter_auth';
  final username = env['DB_USER'] ?? 'postgres';
  final password = env['DB_PASSWORD'] ?? '';

  print('🔌 Подключение к БД: $username@$host:$port/$database');

  final conn = PostgreSQLConnection(
    host, port, database,
    username: username,
    password: password,
    timeoutInSeconds: 30,
  );

  try {
    await conn.open();
    await conn.execute("SET client_encoding TO 'UTF8'");
    print('✓ Подключение установлено');
  } catch (e) {
    print('✗ Ошибка подключения: $e');
    exit(1);
  }

  // Убедиться что таблица schema_migrations существует
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version    TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  ''');

  // Прочитать уже применённые версии
  final applied = <String>{};
  final rows = await conn.query('SELECT version FROM schema_migrations ORDER BY version');
  for (final row in rows) {
    applied.add(row[0] as String);
  }

  // Найти файлы миграций
  final migrationsDir = Directory('database/migrations');
  if (!migrationsDir.existsSync()) {
    print('✗ Каталог database/migrations не найден');
    exit(1);
  }

  final files = migrationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    print('ℹ Миграций не найдено в ${migrationsDir.path}');
    exit(0);
  }

  int appliedCount = 0;
  int skippedCount = 0;

  for (final file in files) {
    final version = file.uri.pathSegments.last; // имя файла, напр. 001_initial_schema.sql

    if (applied.contains(version)) {
      print('  [SKIP] $version — уже применена');
      skippedCount++;
      continue;
    }

    final sql = file.readAsStringSync();
    print('  [RUN]  $version ...');

    try {
      await conn.transaction((ctx) async {
        // Postgres не поддерживает DDL транзакции для некоторых команд,
        // но большинство DML и CREATE TABLE IF NOT EXISTS — безопасны.
        await ctx.execute(sql);
        await ctx.execute(
          'INSERT INTO schema_migrations (version) VALUES (@v)',
          substitutionValues: {'v': version},
        );
      });
      print('  [OK]   $version');
      appliedCount++;
    } catch (e) {
      print('  [ERR]  $version: $e');
      await conn.close();
      exit(1);
    }
  }

  await conn.close();

  print('');
  print('Готово: применено $appliedCount, пропущено $skippedCount.');
}
