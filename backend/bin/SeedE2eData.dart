import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';

/// Сидирует admin-пользователя в основную БД перед e2e-тестами.
/// Безопасен для многократного запуска (идемпотентен).
///
/// Переменные окружения: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD.
Future<void> main() async {
  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'eshkush';
  final dbUser = Platform.environment['DB_USER'] ?? 'postgres';
  final dbPass = Platform.environment['DB_PASSWORD'] ?? '';

  final conn = PostgreSQLConnection(host, port, dbName,
      username: dbUser, password: dbPass);
  await conn.open();

  try {
    // ── Admin user ────────────────────────────────────────────────────────────
    final existing = await conn.query(
      "SELECT id FROM users WHERE username = 'adminuser'",
    );

    int adminId;
    if (existing.isEmpty) {
      final cost = int.tryParse(Platform.environment['BCRYPT_LOG_ROUNDS'] ?? '12') ?? 12;
      final hash = BCrypt.hashpw('Admin@1234', BCrypt.gensalt(logRounds: cost));

      final rows = await conn.query(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES ('adminuser', @hash, 'admin@eshkush.test', '+70000000000', 'admin', CURRENT_TIMESTAMP)
        RETURNING id
        ''',
        substitutionValues: {'hash': hash},
      );
      adminId = rows.first[0] as int;
      print('[seed] Создан admin-пользователь: adminuser (id=$adminId)');
    } else {
      await conn.execute(
        "UPDATE users SET role = 'admin' WHERE username = 'adminuser'",
      );
      adminId = existing.first[0] as int;
      print('[seed] admin-пользователь уже существует, роль обновлена (id=$adminId)');
    }

    // ── City ──────────────────────────────────────────────────────────────────
    final cityRows = await conn.query(
      "SELECT id FROM cities WHERE name = 'Тестовый город'",
    );
    int cityId;
    if (cityRows.isEmpty) {
      final inserted = await conn.query(
        "INSERT INTO cities (name) VALUES ('Тестовый город') RETURNING id",
      );
      cityId = inserted.first[0] as int;
      print('[seed] Создан город: Тестовый город (id=$cityId)');
    } else {
      cityId = cityRows.first[0] as int;
      print('[seed] Город уже существует (id=$cityId)');
    }

    // ── Partner ───────────────────────────────────────────────────────────────
    final partnerRows = await conn.query(
      "SELECT id FROM partners WHERE name = 'Тестовый партнёр'",
    );
    if (partnerRows.isEmpty) {
      final inserted = await conn.query(
        '''
        INSERT INTO partners (user_id, name, contact_email)
        VALUES (@userId, 'Тестовый партнёр', 'partner@eshkush.test')
        RETURNING id
        ''',
        substitutionValues: {'userId': adminId},
      );
      final partnerId = inserted.first[0] as int;
      print('[seed] Создан партнёр: Тестовый партнёр (id=$partnerId)');
    } else {
      print('[seed] Партнёр уже существует (id=${partnerRows.first[0]})');
    }
  } finally {
    await conn.close();
  }
}
