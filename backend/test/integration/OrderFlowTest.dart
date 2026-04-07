import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../helpers/TestEnv.dart';

// ─── HTTP-клиент ──────────────────────────────────────────────────────────────

Future<(int, dynamic)> req(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final client = HttpClient();
  try {
    final rq = await client.openUrl(method, Uri.parse('$integrationBase$path'));
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
    dynamic parsed;
    try { parsed = jsonDecode(raw); } catch (_) { parsed = raw; }
    return (rs.statusCode, parsed);
  } finally {
    client.close();
  }
}

Future<bool> _serverAvailable() async {
  try {
    final (code, _) = await req('GET', '/');
    return code == 200;
  } catch (_) {
    return false;
  }
}

Future<String?> _login(String user, String pass) async {
  try {
    final (code, body) = await req('POST', '/login', body: {'username': user, 'password': pass});
    if (code == 200 && body is Map) return body['access_token'] as String?;
    return null;
  } catch (_) {
    return null;
  }
}

void main() {
  late String? adminToken;
  late int? partnerId;
  late int? cityId;
  final ts = DateTime.now().millisecondsSinceEpoch;

  setUpAll(() async {
    if (!await _serverAvailable()) return;
    adminToken = await _login(kAdminUser, kAdminPass);
    if (adminToken == null) return;

    // Получаем первого партнёра и первый город для создания точки
    final (_, partners) = await req('GET', '/partners', token: adminToken);
    if (partners is List && partners.isNotEmpty) {
      partnerId = (partners.first as Map)['id'] as int?;
    }
    final (_, cities) = await req('GET', '/cities', token: adminToken);
    if (cities is List && cities.isNotEmpty) {
      cityId = (cities.first as Map)['id'] as int?;
    }
  });

  // ─── История заказов (GET) ────────────────────────────────────────────────
  group('GET /order-history', () {
    test('моя история → 200 + список', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('GET', '/order-history', token: adminToken);
      expect(code, 200, reason: jsonEncode(body));
      expect(body, isA<List>());
    });

    test('по userId=2 → 200 + список', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('GET', '/order-history/user?userId=2', token: adminToken);
      expect(code, 200);
      expect(body, isA<List>());
    });

    test('по статусу pending → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('GET', '/order-history/by-status?status=pending', token: adminToken);
      expect(code, 200);
      expect(body, isA<List>());
    });

    test('диапазон дат → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req(
        'GET', '/order-history/by-dates?startDate=2024-01-01&endDate=2026-12-31',
        token: adminToken,
      );
      expect(code, 200);
    });
  });

  // ─── Валидация POST /order-history ────────────────────────────────────────
  group('POST /order-history — валидация', () {
    test('пустое тело → 400', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('POST', '/order-history', body: {}, token: adminToken);
      expect(code, 400, reason: jsonEncode(body));
    });

    test('без orderDate → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('POST', '/order-history', body: {
        'orderId': 1,
        'pointId': 1,
        'userId': 2,
        // нет orderDate
      }, token: adminToken);
      expect(code, greaterThanOrEqualTo(400));
    });

    test('некорректный orderId (0) → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('POST', '/order-history', body: {
        'orderId': 0,
        'pointId': 1,
        'userId': 2,
        'orderDate': '2024-01-01',
      }, token: adminToken);
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── Действия с заказами (GET) ────────────────────────────────────────────
  group('GET /order-actions', () {
    test('активные → 200 + список', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('GET', '/order-actions', token: adminToken);
      expect(code, 200);
      expect(body, isA<List>());
    });

    test('по orderId → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('GET', '/order-actions/by-order?orderId=1', token: adminToken);
      expect(code, 200);
    });
  });

  // ─── Валидация POST /order-actions ────────────────────────────────────────
  group('POST /order-actions — валидация', () {
    test('пустое тело → 400', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('POST', '/order-actions', body: {}, token: adminToken);
      expect(code, 400);
    });

    test('без partnerId → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('POST', '/order-actions', body: {
        'orderId': 1,
        'actionDescription': 'Тест',
        // нет partnerId
      }, token: adminToken);
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── Платёжные транзакции (GET) ───────────────────────────────────────────
  group('GET /payment-transactions', () {
    test('мои транзакции → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, body) = await req('GET', '/payment-transactions', token: adminToken);
      expect(code, 200);
      expect(body, isA<List>());
    });

    test('по user_id → 200', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('GET', '/payment-transactions/user?user_id=2', token: adminToken);
      expect(code, 200);
    });

    test('без user_id → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('GET', '/payment-transactions/user', token: adminToken);
      expect(code, greaterThanOrEqualTo(400));
    });
  });

  // ─── Создание точки + продукта (полный сценарий) ──────────────────────────
  group('Создание точки и продукта', () {
    int? createdPointId;
    int? createdProductId;

    test('POST /points → 200/201 + id', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null || partnerId == null || cityId == null) {
        markTestSkipped('Нет токена/данных'); return;
      }
      final (code, body) = await req('POST', '/points', body: {
        'name': 'OrderFlowPoint$ts',
        'address': 'ул. Интеграционная, 1',
        'city_id': cityId,
        'partner_id': partnerId,
        'latitude': 55.75,
        'longitude': 37.62,
        'opening_hours': '09:00',
        'closing_hours': '22:00',
      }, token: adminToken);
      expect(code, anyOf(200, 201), reason: jsonEncode(body));
      if (body is Map && body['id'] != null) {
        createdPointId = body['id'] as int;
      }
    });

    test('POST /products → 200/201 + id', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null || createdPointId == null) {
        markTestSkipped('Нет токена или точки'); return;
      }
      final (code, body) = await req('POST', '/products', body: {
        'name': 'OrderFlowProduct$ts',
        'description': 'Тестовый продукт',
        'price': 199.0,
        'point_id': createdPointId,
        'partner_id': partnerId,
      }, token: adminToken);
      expect(code, anyOf(200, 201), reason: jsonEncode(body));
      if (body is Map && body['id'] != null) {
        createdProductId = body['id'] as int;
      }
    });

    test('POST /products — отрицательная цена → 4xx', () async {
      if (!await _serverAvailable()) { markTestSkipped('Сервер недоступен'); return; }
      if (adminToken == null) { markTestSkipped('Нет токена'); return; }
      final (code, _) = await req('POST', '/products', body: {
        'name': 'BadProduct',
        'price': -50.0,
        'point_id': createdPointId ?? 1,
        'partner_id': partnerId ?? 1,
      }, token: adminToken);
      expect(code, greaterThanOrEqualTo(400));
    });

    // Очистка
    tearDownAll(() async {
      if (adminToken == null) return;
      if (createdProductId != null) {
        await req('DELETE', '/products/$createdProductId', token: adminToken);
      }
      if (createdPointId != null) {
        await req('DELETE', '/points/$createdPointId', token: adminToken);
      }
    });
  });
}