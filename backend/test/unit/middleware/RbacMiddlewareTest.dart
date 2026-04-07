import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:backend/middleware/RbacMiddleware.dart';

// ─── Вспомогательные функции ──────────────────────────────────────────────────

/// Создаёт GET-запрос с заданным путём и опциональным JWT-payload в контексте.
Request makeRequest(String path, {Map<String, dynamic>? user}) {
  final context = <String, Object>{};
  if (user != null) context['user'] = user;
  return Request('GET', Uri.parse('http://localhost/$path'), context: context);
}

/// Простой innerHandler, всегда отвечающий 200.
Handler okHandler = (_) async => Response.ok('ok');

/// Декодирует тело ответа как JSON-map.
Future<Map<String, dynamic>> decodeBody(Response resp) async =>
    jsonDecode(await resp.readAsString()) as Map<String, dynamic>;

void main() {
  // Правила, аналогичные продакшн-конфигу
  final rules = {
    'action-logs':       {'admin'},
    'error-logs':        {'admin'},
    'cache':             {'admin'},
    'partner-statistics': {'admin', 'support'},
    'promo-codes':       {'admin', 'support'},
    'point-categories':  {'admin', 'support'},
    'product-categories': {'admin', 'support'},
  };

  final middleware = RbacMiddleware.withRoleRules(rules);
  final handler = middleware(okHandler);

  // ─── Нет правила для пути → пропустить ────────────────────────────────────
  group('путь без RBAC-правила → проходит любая роль', () {
    for (final path in ['products', 'points', 'orders', 'reviews']) {
      test(path, () async {
        final req = makeRequest(path, user: {'id': 1, 'role': 'user'});
        final resp = await handler(req);
        expect(resp.statusCode, 200);
      });
    }

    test('нет контекста user — тоже проходит для неограниченного пути', () async {
      final req = makeRequest('products');
      final resp = await handler(req);
      expect(resp.statusCode, 200);
    });
  });

  // ─── Admin-only пути ──────────────────────────────────────────────────────
  group('admin-only: action-logs, error-logs, cache', () {
    for (final path in ['action-logs', 'error-logs', 'cache']) {
      test('admin проходит: $path', () async {
        final req = makeRequest(path, user: {'id': 1, 'role': 'admin'});
        final resp = await handler(req);
        expect(resp.statusCode, 200);
      });

      test('user → 403: $path', () async {
        final req = makeRequest(path, user: {'id': 2, 'role': 'user'});
        final resp = await handler(req);
        expect(resp.statusCode, 403);
      });

      test('support → 403: $path', () async {
        final req = makeRequest(path, user: {'id': 3, 'role': 'support'});
        final resp = await handler(req);
        expect(resp.statusCode, 403);
      });

      test('нет user в контексте → 403: $path', () async {
        final req = makeRequest(path);
        final resp = await handler(req);
        expect(resp.statusCode, 403);
      });
    }
  });

  // ─── Admin + support пути ─────────────────────────────────────────────────
  group('admin+support: partner-statistics, promo-codes, *-categories', () {
    for (final path in [
      'partner-statistics', 'promo-codes', 'point-categories', 'product-categories'
    ]) {
      test('admin проходит: $path', () async {
        final req = makeRequest(path, user: {'id': 1, 'role': 'admin'});
        expect((await handler(req)).statusCode, 200);
      });

      test('support проходит: $path', () async {
        final req = makeRequest(path, user: {'id': 2, 'role': 'support'});
        expect((await handler(req)).statusCode, 200);
      });

      test('user → 403: $path', () async {
        final req = makeRequest(path, user: {'id': 3, 'role': 'user'});
        expect((await handler(req)).statusCode, 403);
      });

      test('partner → 403: $path', () async {
        final req = makeRequest(path, user: {'id': 4, 'role': 'partner'});
        expect((await handler(req)).statusCode, 403);
      });
    }
  });

  // ─── Регистронезависимость ────────────────────────────────────────────────
  group('роль без учёта регистра', () {
    test('ADMIN (верхний регистр) проходит admin-only путь', () async {
      final req = makeRequest('action-logs', user: {'id': 1, 'role': 'ADMIN'});
      expect((await handler(req)).statusCode, 200);
    });

    test('Admin (смешанный) проходит admin-only путь', () async {
      final req = makeRequest('cache', user: {'id': 1, 'role': 'Admin'});
      expect((await handler(req)).statusCode, 200);
    });
  });

  // ─── Тело 403-ответа ─────────────────────────────────────────────────────
  group('структура 403-ответа', () {
    test('содержит {error: {code: FORBIDDEN, message: ...}}', () async {
      final req = makeRequest('cache', user: {'id': 2, 'role': 'user'});
      final resp = await handler(req);
      expect(resp.statusCode, 403);
      final body = await decodeBody(resp);
      expect((body['error'] as Map)['code'], 'FORBIDDEN');
      expect((body['error'] as Map)['message'], isNotEmpty);
    });
  });

  // ─── Префиксное совпадение ────────────────────────────────────────────────
  group('префиксное совпадение пути', () {
    test('action-logs/recent совпадает с правилом action-logs', () async {
      final req = makeRequest('action-logs/recent', user: {'id': 2, 'role': 'user'});
      expect((await handler(req)).statusCode, 403);
    });

    test('cache/stats совпадает с правилом cache', () async {
      final req = makeRequest('cache/stats', user: {'id': 1, 'role': 'admin'});
      expect((await handler(req)).statusCode, 200);
    });
  });

  // ─── isOwnerOrElevated ────────────────────────────────────────────────────
  group('RbacMiddleware.isOwnerOrElevated', () {
    Request reqWithUser(int userId, String role) =>
        makeRequest('any', user: {'id': userId, 'role': role});

    test('userId совпадает с ownerId → true', () {
      expect(RbacMiddleware.isOwnerOrElevated(reqWithUser(5, 'user'), 5), isTrue);
    });

    test('userId не совпадает и роль не elevated → false', () {
      expect(RbacMiddleware.isOwnerOrElevated(reqWithUser(5, 'user'), 7), isFalse);
    });

    test('admin всегда elevated → true', () {
      expect(RbacMiddleware.isOwnerOrElevated(reqWithUser(1, 'admin'), 999), isTrue);
    });

    test('кастомная elevated роль', () {
      expect(
        RbacMiddleware.isOwnerOrElevated(
          reqWithUser(1, 'support'), 999,
          elevatedRoles: {'support'},
        ),
        isTrue,
      );
    });

    test('нет пользователя в контексте → false', () {
      final req = makeRequest('any');
      expect(RbacMiddleware.isOwnerOrElevated(req, 1), isFalse);
    });
  });
}