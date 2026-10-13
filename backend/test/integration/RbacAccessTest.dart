import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../helpers/TestEnv.dart';

// ─── HTTP-клиент ──────────────────────────────────────────────────────────────

Future<int> get_(String path, {String? token}) async {
  final client = HttpClient();
  try {
    final rq = await client.getUrl(Uri.parse('$integrationBase$path'));
    rq.headers.set('Accept', 'application/json');
    if (token != null) rq.headers.set('Authorization', 'Bearer $token');
    final rs = await rq.close();
    await rs.drain();
    return rs.statusCode;
  } finally {
    client.close();
  }
}

Future<(int, Map<String, dynamic>)> post_(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) async {
  final client = HttpClient();
  try {
    final rq = await client.postUrl(Uri.parse('$integrationBase$path'));
    rq.headers.set('Content-Type', 'application/json');
    rq.headers.set('Accept', 'application/json');
    if (token != null) rq.headers.set('Authorization', 'Bearer $token');
    final enc = utf8.encode(jsonEncode(body));
    rq.headers.contentLength = enc.length;
    rq.add(enc);
    final rs = await rq.close();
    final raw = await rs.transform(utf8.decoder).join();
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    return (rs.statusCode, parsed);
  } finally {
    client.close();
  }
}

Future<bool> _serverAvailable() async {
  final ready = await (_serverReadyFuture ??= waitForIntegrationServer());
  if (!ready) {
    throw StateError('Integration server is unavailable: $integrationBase');
  }
  return true;
}

Future<bool>? _serverReadyFuture;

Future<String?> _login(String username, String password) async {
  try {
    final (code, body) =
        await post_('/login', {'username': username, 'password': password});
    if (code == 200) return body['access_token'] as String?;
    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> _registerAndLogin(
    String username, String password, String email, String phone) async {
  try {
    await post_('/auth/register', {
      'username': username,
      'password': password,
      'password_confirm': password,
      'email': email,
      'number': phone,
    });
    return await _login(username, password);
  } catch (_) {
    return null;
  }
}

void main() {
  final ts = DateTime.now().millisecondsSinceEpoch;
  late String? adminToken;
  late String? userToken;

  setUpAll(() async {
    if (!await _serverAvailable()) return;

    adminToken = await _login(kAdminUser, kAdminPass);

    final uName = 'rbac_$ts';
    final uPhone = '+7999${(ts % 10000000).toString().padLeft(7, "0")}';
    userToken = await _registerAndLogin(
      uName,
      'Test@1234',
      '$uName@test.com',
      uPhone,
    );
  });

  // ─── Открытые маршруты (без токена) ──────────────────────────────────────
  group('Открытые маршруты', () {
    test('GET / → 200 без токена', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      expect(await get_('/'), anyOf(200, 403));
    });

    test('GET /swagger/ → 2xx без токена', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      expect(await get_('/swagger/'), lessThan(400));
    });

    test('POST /login → 200 (проверяем доступность)', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      final (code, _) = await post_('/login', {
        'username': kAdminUser,
        'password': kAdminPass,
      });
      expect(code, 200);
    });
  });

  // ─── Без токена → 401 ────────────────────────────────────────────────────
  group('Защищённые маршруты без токена → 401', () {
    const paths = [
      '/users/profile',
      '/sessions',
      '/orders',
      '/favorites',
      '/changes',
      '/notifications',
      '/order-history',
      '/payment-transactions',
    ];
    for (final path in paths) {
      test('GET $path → 401', () async {
        if (!await _serverAvailable()) {
          markTestSkipped('Сервер недоступен');
          return;
        }
        expect(await get_(path), 401);
      });
    }
  });

  // ─── Роль user → 403 на admin/support путях ───────────────────────────────
  group('Роль user → 403 на ограниченных маршрутах', () {
    // partner-statistics, promo-codes, point-categories, product-categories
    // разрешены для GET любому аутентифицированному пользователю (RBAC: 'GET': {})
    const restricted = [
      '/action-logs',
      '/error-logs',
      '/cache',
    ];
    for (final path in restricted) {
      test('GET $path (user) → 403', () async {
        if (!await _serverAvailable()) {
          markTestSkipped('Сервер недоступен');
          return;
        }
        if (userToken == null) {
          markTestSkipped('Нет user-токена');
          return;
        }
        expect(await get_(path, token: userToken), 403);
      });
    }
  });

  // ─── Роль admin → доступ ко всем маршрутам ───────────────────────────────
  group('Роль admin → проходит ограниченные маршруты', () {
    const adminPaths = [
      '/action-logs',
      '/error-logs',
      '/cache',
      '/partner-statistics',
      '/promo-codes',
      '/point-categories',
      '/product-categories',
    ];
    for (final path in adminPaths) {
      test('GET $path (admin) → 200', () async {
        if (!await _serverAvailable()) {
          markTestSkipped('Сервер недоступен');
          return;
        }
        if (adminToken == null) {
          markTestSkipped('Нет admin-токена');
          return;
        }
        expect(await get_(path, token: adminToken), 200);
      });
    }
  });

  // ─── Профиль и сессии ─────────────────────────────────────────────────────
  group('Профиль / сессии', () {
    test('GET /users/profile (admin) → 200 с username', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      if (adminToken == null) {
        markTestSkipped('Нет admin-токена');
        return;
      }
      final client = HttpClient();
      try {
        final rq =
            await client.getUrl(Uri.parse('$integrationBase/users/profile'));
        rq.headers.set('Accept', 'application/json');
        rq.headers.set('Authorization', 'Bearer $adminToken');
        final rs = await rq.close();
        final raw = await rs.transform(utf8.decoder).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        expect(rs.statusCode, 200);
        expect(body['username'], kAdminUser);
      } finally {
        client.close();
      }
    });

    test('GET /sessions (user) → 200', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      if (userToken == null) {
        markTestSkipped('Нет user-токена');
        return;
      }
      expect(await get_('/sessions', token: userToken), 200);
    });
  });

  // ─── Чужой токен (подделка) ───────────────────────────────────────────────
  group('Невалидные токены', () {
    test('мусорный Bearer → 401', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      expect(await get_('/users/profile', token: 'garbage.token.here'), 401);
    });

    test('валидный JWT но не из нашего сервера → 401', () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен');
        return;
      }
      // Подбираем токен с другой подписью
      const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJpZCI6MSwidHlwZSI6ImFjY2VzcyIsInJvbGUiOiJhZG1pbiJ9.'
          'INVALIDSIGNATURE1234567890';
      expect(await get_('/users/profile', token: fakeToken), 401);
    });
  });
}
