import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/UserSessionRepository.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestEnv.dart';

void main() {
  if (!TestDb.isAvailable) {
    print('SKIP: TEST_DB_HOST не задан, пропуск интеграционных тестов AuthService');
    return;
  }

  late AuthService sut;

  setUpAll(() async {
    AppConfig.initForTesting();
    final conn = await TestDb.connect();
    sut = AuthService(UserRepository(conn), UserSessionRepository(conn));
  });

  setUp(() async {
    final conn = await TestDb.connect();
    // Сносим сессии и пользователей, созданных в тестах (кроме системных)
    await conn.execute(
      "DELETE FROM user_sessions WHERE user_id IN (SELECT id FROM users WHERE username LIKE 'auth_it_%')",
    );
    await conn.execute(
      "DELETE FROM users WHERE username LIKE 'auth_it_%'",
    );
  });

  tearDownAll(() async => TestDb.close());

  // ── register ──────────────────────────────────────────────────────────────
  group('register', () {
    test('создаёт пользователя и возвращает токены', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final result = await sut.register({
        'username': 'auth_it_$ts',
        'email': 'auth_it_$ts@test.com',
        'number': '+7999${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Test@1234',
        'password_confirm': 'Test@1234',
        'role': 'user',
      });

      expect(result['access_token'], isA<String>());
      expect(result['refresh_token'], isA<String>());
      expect(result['user']['username'], 'auth_it_$ts');
      expect(result['user']['role'], 'user');
    });

    test('бросает Exception при дублирующемся username', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'username': 'auth_it_dup_$ts',
        'email': 'dup_$ts@test.com',
        'number': '+7888${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Test@1234',
        'password_confirm': 'Test@1234',
        'role': 'user',
      };
      await sut.register(data);

      expect(
        () => sut.register({...data, 'email': 'other_$ts@test.com'}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('уже существует'),
        )),
      );
    });

    test('бросает при некорректной роли', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      expect(
        () => sut.register({
          'username': 'auth_it_bad_$ts',
          'email': 'bad_$ts@test.com',
          'number': '+7777${(ts % 10000000).toString().padLeft(7, "0")}',
          'password': 'Test@1234',
          'password_confirm': 'Test@1234',
          'role': 'superuser',
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает при невалидном email', () async {
      expect(
        () => sut.register({
          'username': 'auth_it_bademail',
          'email': 'not-an-email',
          'number': '+79001234567',
          'password': 'Test@1234',
          'password_confirm': 'Test@1234',
          'role': 'user',
        }),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── login ─────────────────────────────────────────────────────────────────
  group('login', () {
    late String createdUsername;

    setUp(() async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      createdUsername = 'auth_it_login_$ts';
      await sut.register({
        'username': createdUsername,
        'email': 'login_$ts@test.com',
        'number': '+7666${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Login@1234',
        'password_confirm': 'Login@1234',
        'role': 'user',
      });
    });

    test('возвращает токены при верных учётных данных', () async {
      final result = await sut.login(createdUsername, 'Login@1234');
      expect(result['access_token'], isA<String>());
      expect(result['refresh_token'], isA<String>());
      expect(result['user']['username'], createdUsername);
    });

    test('бросает при неверном пароле', () async {
      expect(
        () => sut.login(createdUsername, 'WrongPassword!'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Неверный'),
        )),
      );
    });

    test('бросает при несуществующем пользователе', () async {
      expect(
        () => sut.login('no_such_user_xyz', 'anyPass'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── refreshToken ──────────────────────────────────────────────────────────
  group('refreshToken', () {
    test('выдаёт новую пару токенов', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final reg = await sut.register({
        'username': 'auth_it_ref_$ts',
        'email': 'ref_$ts@test.com',
        'number': '+7555${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Refresh@1234',
        'password_confirm': 'Refresh@1234',
        'role': 'user',
      });

      final oldRefresh = reg['refresh_token'] as String;
      final result = await sut.refreshToken(oldRefresh);
      expect(result['access_token'], isA<String>());
      expect(result['refresh_token'], isA<String>());
      // Новые токены должны отличаться от старых
      expect(result['refresh_token'], isNot(oldRefresh));
    });

    test('бросает при мусорном refresh-токене', () async {
      expect(
        () => sut.refreshToken('garbage.token.here'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
