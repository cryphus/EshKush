import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../../helpers/TestEnv.dart';

// ─── HTTP-хелперы ─────────────────────────────────────────────────────────────

Future<(int, dynamic)> _get(String path, {String? token}) async {
  final client = HttpClient();
  try {
    final rq = await client.getUrl(Uri.parse('$integrationBase$path'));
    rq.headers.set('Accept', 'application/json');
    if (token != null) rq.headers.set('Authorization', 'Bearer $token');
    final rs = await rq.close();
    final raw = await rs.transform(utf8.decoder).join();
    dynamic body;
    try { body = jsonDecode(raw); } catch (_) { body = raw; }
    return (rs.statusCode, body);
  } finally {
    client.close();
  }
}

Future<(int, dynamic)> _post(
  String path,
  Map<String, dynamic> data, {
  String? token,
}) async {
  final client = HttpClient();
  try {
    final rq = await client.postUrl(Uri.parse('$integrationBase$path'));
    rq.headers.set('Content-Type', 'application/json');
    rq.headers.set('Accept', 'application/json');
    if (token != null) rq.headers.set('Authorization', 'Bearer $token');
    final enc = utf8.encode(jsonEncode(data));
    rq.headers.contentLength = enc.length;
    rq.add(enc);
    final rs = await rq.close();
    final raw = await rs.transform(utf8.decoder).join();
    dynamic body;
    try { body = jsonDecode(raw); } catch (_) { body = raw; }
    return (rs.statusCode, body);
  } finally {
    client.close();
  }
}

Future<bool> _serverAvailable() async {
  try {
    final (code, _) = await _get('/health');
    return code < 500;
  } catch (_) {
    return false;
  }
}

Future<String?> _login(String username, String password) async {
  try {
    final (code, body) = await _post('/login', {
      'username': username,
      'password': password,
    });
    if (code == 200 && body is Map) return body['access_token'] as String?;
    return null;
  } catch (_) {
    return null;
  }
}

// ─── Тесты ───────────────────────────────────────────────────────────────────

void main() {
  late String? adminToken;
  late String? userToken;
  final ts = DateTime.now().millisecondsSinceEpoch;

  setUpAll(() async {
    if (!await _serverAvailable()) return;

    adminToken = await _login(kAdminUser, kAdminPass);

    // Регистрируем тестового пользователя
    final uName = 'api_it_$ts';
    await _post('/auth/register', {
      'username': uName,
      'email': '$uName@test.com',
      'number': '+7900${(ts % 10000000).toString().padLeft(7, "0")}',
      'password': 'Api@1234',
      'password_confirm': 'Api@1234',
    });
    userToken = await _login(uName, 'Api@1234');
  });

  // ─── /health — формат ответа ───────────────────────────────────────────────
  group('GET /health — формат JSON', () {
    test('статус 200 и поле status', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, body) = await _get('/health');
      expect(code, 200);
      expect(body, isA<Map>());
      expect(body['status'], isNotNull);
    });
  });

  // ─── /login — коды ошибок и формат ────────────────────────────────────────
  group('POST /login — коды ошибок', () {
    test('4xx при пустом теле', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await _post('/login', {});
      expect(code, anyOf(400, 401, 422, 429));
    });

    test('401 при неверном пароле', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, body) = await _post('/login', {
        'username': kAdminUser,
        'password': 'wrong_password',
      });
      expect(code, 401);
      expect(body, isA<Map>());
    });

    test('200 возвращает access_token и refresh_token', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет admin-токена'); return; }
      final (code, body) = await _post('/login', {
        'username': kAdminUser,
        'password': kAdminPass,
      });
      expect(code, 200);
      expect(body['access_token'], isA<String>());
      expect(body['refresh_token'], isA<String>());
    });
  });

  // ─── /auth/register — валидация ────────────────────────────────────────────
  group('POST /auth/register — валидация', () {
    test('400/422 при невалидном email', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await _post('/auth/register', {
        'username': 'reg_bad_email',
        'email': 'not-an-email',
        'number': '+79001111111',
        'password': 'Pass@1234',
        'password_confirm': 'Pass@1234',
      });
      expect(code, anyOf(400, 422));
    });

    test('400/409/422 при дублирующемся username', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final name = 'api_dup_$ts';
      await _post('/auth/register', {
        'username': name,
        'email': '$name@test.com',
        'number': '+7901${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Pass@1234',
        'password_confirm': 'Pass@1234',
      });
      final (code, _) = await _post('/auth/register', {
        'username': name,
        'email': 'other_$ts@test.com',
        'number': '+7902${(ts % 10000000).toString().padLeft(7, "0")}',
        'password': 'Pass@1234',
        'password_confirm': 'Pass@1234',
      });
      expect(code, anyOf(400, 409, 422));
    });
  });

  // ─── /users/profile — формат профиля ──────────────────────────────────────
  group('GET /users/profile — формат ответа', () {
    test('200 содержит username и id', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет admin-токена'); return; }
      final (code, body) = await _get('/users/profile', token: adminToken);
      expect(code, 200);
      expect(body['username'], kAdminUser);
      expect(body['id'], isA<int>());
    });

    test('401 без токена', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await _get('/users/profile');
      expect(code, 401);
    });
  });

  // ─── /orders — пагинация ──────────────────────────────────────────────────
  group('GET /orders — пагинация и формат', () {
    test('200 с limit/offset', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет admin-токена'); return; }
      final (code, body) = await _get('/orders?limit=5&offset=0', token: adminToken);
      expect(code, 200);
      // Ответ либо список, либо объект с полем data/items
      if (body is List) {
        expect(body.length, lessThanOrEqualTo(5));
      } else if (body is Map) {
        expect(body.containsKey('data') || body.containsKey('items') || body.containsKey('orders'), isTrue);
      }
    });

    test('401 без токена', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await _get('/orders');
      expect(code, 401);
    });
  });

  // ─── /points — открытый список ─────────────────────────────────────────────
  group('GET /points — открытый эндпоинт', () {
    test('возвращает 2xx или 401 (в зависимости от конфигурации auth)', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет admin-токена'); return; }
      final (code, _) = await _get('/points', token: adminToken);
      expect(code, lessThan(400));
    });
  });

  // ─── Несуществующий маршрут ────────────────────────────────────────────────
  group('4xx для несуществующего маршрута', () {
    test('GET /no-such-route → 401 или 404', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (code, _) = await _get('/no-such-route-xyz');
      // JWT проверка выполняется до роутинга, поэтому без токена — 401
      expect(code, anyOf(401, 404));
    });
  });

  // ─── Ошибочные запросы — формат тела ошибки ───────────────────────────────
  group('Формат тела ошибок', () {
    test('401-ответ содержит message или error', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      final (_, body) = await _get('/users/profile');
      if (body is Map) {
        expect(
          body.containsKey('message') || body.containsKey('error'),
          isTrue,
          reason: 'Тело ошибки должно содержать "message" или "error", got: $body',
        );
      }
    });

    test('403-ответ содержит message или error', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (userToken == null) { markTestSkipped('Нет user-токена'); return; }
      final (_, body) = await _get('/action-logs', token: userToken);
      if (body is Map) {
        expect(
          body.containsKey('message') || body.containsKey('error'),
          isTrue,
          reason: 'Тело ошибки должно содержать "message" или "error", got: $body',
        );
      }
    });
  });
}
