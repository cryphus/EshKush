import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../helpers/TestEnv.dart';

// ─── HTTP-клиент ──────────────────────────────────────────────────────────────

Future<(int, Map<String, dynamic>)> http(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$integrationBase$path');
    final rq = await client.openUrl(method, uri);
    rq.headers.set('Content-Type', 'application/json');
    rq.headers.set('Accept', 'application/json');
    if (token != null) rq.headers.set('Authorization', 'Bearer $token');
    if (body != null) {
      final enc = utf8.encode(jsonEncode(body));
      rq.headers.contentLength = enc.length;
      rq.add(enc);
    }
    final rs = await rq.close();
    final raw = await rs.transform(utf8.decoder).join();
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    return (rs.statusCode, parsed);
  } finally {
    client.close();
  }
}

Future<bool> _serverAvailable() async {
  try {
    final (code, _) = await http('GET', '/');
    return code == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final testUsername = 'inttest_$ts';
  final testEmail = 'inttest_$ts@test.com';
  final testPassword = 'IntTest@1234';
  final testPhone = '+7999${(ts % 10000000).toString().padLeft(7, "0")}';

  String accessToken = '';
  String refreshToken = '';

  setUpAll(() async {
    if (!await _serverAvailable()) {
      // Тесты пропускаются gracefully, если сервер не запущен
    }
  });

  // ─── Регистрация ──────────────────────────────────────────────────────────
  group('POST /auth/register', () {
    test('регистрация нового пользователя → 200/201', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен: $integrationBase');
        return;
      }
      final (code, body) = await http('POST', '/auth/register', body: {
        'username': testUsername,
        'password': testPassword,
        'password_confirm': testPassword,
        'email': testEmail,
        'number': testPhone,
      });
      expect(code, anyOf(200, 201),
          reason: 'тело: ${jsonEncode(body)}');
    });

    test('повторная регистрация того же username → 409', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/register', body: {
        'username': testUsername,
        'password': testPassword,
        'password_confirm': testPassword,
        'email': 'other_$ts@test.com',
        'number': '+7888${(ts % 10000000).toString().padLeft(7, "0")}',
      });
      expect(code, 409);
    });

    test('пароли не совпадают → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/register', body: {
        'username': 'other_$ts',
        'password': testPassword,
        'password_confirm': 'WRONG@pass1',
        'email': 'other2_$ts@test.com',
        'number': '+7777${(ts % 10000000).toString().padLeft(7, "0")}',
      });
      expect(code, greaterThanOrEqualTo(400));
    });

    test('некорректный email → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/register', body: {
        'username': 'badmail_$ts',
        'password': testPassword,
        'password_confirm': testPassword,
        'email': 'not-an-email',
        'number': testPhone,
      });
      expect(code, greaterThanOrEqualTo(400));
    });

    test('слабый пароль → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/register', body: {
        'username': 'weakpass_$ts',
        'password': 'weak',
        'password_confirm': 'weak',
        'email': 'weakpass_$ts@test.com',
        'number': testPhone,
      });
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── Логин ────────────────────────────────────────────────────────────────
  group('POST /login', () {
    test('корректные credentials → 200 + access_token + refresh_token', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, body) = await http('POST', '/login', body: {
        'username': testUsername,
        'password': testPassword,
      });
      expect(code, 200, reason: 'тело: ${jsonEncode(body)}');
      expect(body['access_token'], isA<String>());
      expect((body['access_token'] as String), isNotEmpty);
      expect(body['refresh_token'], isA<String>());
      expect((body['refresh_token'] as String), isNotEmpty);

      accessToken = body['access_token'] as String;
      refreshToken = body['refresh_token'] as String;
    });

    test('неверный пароль → 401', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/login', body: {
        'username': testUsername,
        'password': 'WrongPass@1',
      });
      expect(code, 401);
    });

    test('несуществующий пользователь → 401', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/login', body: {
        'username': 'no_such_user_$ts',
        'password': 'AnyPass@1',
      });
      expect(code, 401);
    });

    test('отсутствует password → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/login', body: {'username': testUsername});
      expect(code, greaterThanOrEqualTo(400));
    });

    test('отсутствует username → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/login', body: {'password': testPassword});
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── Защищённый эндпоинт с токеном ───────────────────────────────────────
  group('Авторизованный доступ', () {
    test('GET /users/profile с валидным токеном → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (accessToken.isEmpty) { markTestSkipped('Нет токена (логин не прошёл)'); return; }
      final (code, body) = await http('GET', '/users/profile', token: accessToken);
      expect(code, 200, reason: jsonEncode(body));
      expect(body['username'], testUsername);
    });

    test('GET /users/profile без токена → 401', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('GET', '/users/profile');
      expect(code, 401);
    });

    test('GET /users/profile с мусорным токеном → 401', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('GET', '/users/profile', token: 'invalid.jwt.token');
      expect(code, 401);
    });
  });

  // ─── Refresh токена ───────────────────────────────────────────────────────
  group('POST /auth/refresh', () {
    test('валидный refresh_token → 200 + новый access_token', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (refreshToken.isEmpty) { markTestSkipped('Нет refresh токена'); return; }
      final (code, body) = await http('POST', '/auth/refresh', body: {
        'refresh_token': refreshToken,
      });
      expect(code, 200, reason: jsonEncode(body));
      expect(body['access_token'], isA<String>());
      expect((body['access_token'] as String), isNotEmpty);

      // Обновляем токены для следующих тестов
      accessToken = body['access_token'] as String;
      if (body['refresh_token'] != null) {
        refreshToken = body['refresh_token'] as String;
      }
    });

    test('невалидный refresh_token → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/refresh', body: {
        'refresh_token': 'invalid.refresh.token',
      });
      expect(code, greaterThanOrEqualTo(400));
    });

    test('отсутствует refresh_token → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/refresh', body: {});
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── check_user ───────────────────────────────────────────────────────────
  group('POST /auth/check_user', () {
    test('существующий номер → 200 + exists=true', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, body) = await http('POST', '/auth/check_user', body: {
        'number': testPhone,
      });
      expect(code, 200);
      expect(body['exists'], isTrue);
    });

    test('несуществующий номер → 200 + exists=false', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, body) = await http('POST', '/auth/check_user', body: {
        'number': '+70000000000',
      });
      expect(code, 200);
      expect(body['exists'], isFalse);
    });

    test('отсутствует number → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await http('POST', '/auth/check_user', body: {});
      expect(code, greaterThanOrEqualTo(400));
    });
  });
}