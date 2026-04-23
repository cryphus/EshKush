import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/middleware/SecurityMiddleware.dart';
import 'package:backend/utils/AuthUtils.dart';
import '../../helpers/FakeSessionRepo.dart';
import '../../helpers/TestEnv.dart';

// ─── Вспомогательные функции ──────────────────────────────────────────────────

Request makeGet(String path, {Map<String, String>? headers}) => Request(
      'GET',
      Uri.parse('http://localhost/$path'),
      headers: headers ?? {},
    );

Request makeOptions(String path) =>
    Request('OPTIONS', Uri.parse('http://localhost/$path'));

Handler okHandler = (_) async => Response.ok('ok');

Future<Map<String, dynamic>> decodeBody(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

void main() {
  // ─── securityHeaders ──────────────────────────────────────────────────────
  group('securityHeaders', () {
    late Handler handler;

    setUpAll(() {
      handler = SecurityMiddleware.securityHeaders()(okHandler);
    });

    test('X-Content-Type-Options: nosniff', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['x-content-type-options'], 'nosniff');
    });

    test('X-Frame-Options: DENY', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['x-frame-options'], 'DENY');
    });

    test('Content-Security-Policy присутствует', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['content-security-policy'], isNotEmpty);
    });

    test('Strict-Transport-Security присутствует', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['strict-transport-security'], contains('max-age='));
    });

    test('Referrer-Policy: strict-origin-when-cross-origin', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['referrer-policy'], 'strict-origin-when-cross-origin');
    });

    test('Permissions-Policy присутствует', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['permissions-policy'], isNotEmpty);
    });

    test('Cross-Origin-Opener-Policy: same-origin', () async {
      final resp = await handler(makeGet(''));
      expect(resp.headers['cross-origin-opener-policy'], 'same-origin');
    });

    test('исходный ответ innerHandler доходит (код 200)', () async {
      final resp = await handler(makeGet(''));
      expect(resp.statusCode, 200);
    });
  });

  // ─── rateLimiter ──────────────────────────────────────────────────────────
  group('rateLimiter', () {
    // Используем уникальные IP для изоляции тестов от статического состояния.
    int _ipCounter = 0;
    String uniqueIp() => '10.0.${_ipCounter ~/ 256}.${_ipCounter++ % 256}';

    late Handler handler;
    setUpAll(() {
      AppConfig.initForTesting();
      handler = SecurityMiddleware.rateLimiter()(okHandler);
    });

    test('первые 100 запросов с одного IP проходят', () async {
      final ip = uniqueIp();
      for (var i = 0; i < 100; i++) {
        final req = Request('GET', Uri.parse('http://localhost/'),
            headers: {'x-forwarded-for': ip});
        final resp = await handler(req);
        expect(resp.statusCode, 200, reason: 'запрос #$i должен пройти');
      }
    });

    test('101-й запрос → 429', () async {
      final ip = uniqueIp();
      for (var i = 0; i < 100; i++) {
        await handler(Request('GET', Uri.parse('http://localhost/'),
            headers: {'x-forwarded-for': ip}));
      }
      final resp = await handler(Request('GET', Uri.parse('http://localhost/'),
          headers: {'x-forwarded-for': ip}));
      expect(resp.statusCode, 429);
    });

    test('разные IP независимы', () async {
      final ip1 = uniqueIp();
      final ip2 = uniqueIp();
      // Заполняем лимит для ip1
      for (var i = 0; i < 100; i++) {
        await handler(Request('GET', Uri.parse('http://localhost/'),
            headers: {'x-forwarded-for': ip1}));
      }
      // ip2 ещё не исчерпал лимит
      final resp = await handler(Request('GET', Uri.parse('http://localhost/'),
          headers: {'x-forwarded-for': ip2}));
      expect(resp.statusCode, 200);
    });
  });

  // ─── checkJWT ─────────────────────────────────────────────────────────────
  group('checkJWT', skip: jwtEnvReady ? null : kJwtSkipReason, () {
    late FakeSessionRepository repo;
    late Handler makeHandler;

    setUp(() {
      repo = FakeSessionRepository();
      makeHandler = SecurityMiddleware.checkJWT(
        repo,
        openPaths: ['auth', 'login', 'swagger'],
      )(okHandler);
    });

    // ── Открытые маршруты ──────────────────────────────────────────────────
    test('OPTIONS всегда проходит', () async {
      final resp = await makeHandler(makeOptions('protected'));
      expect(resp.statusCode, 200);
    });

    test('пустой путь "/" проходит без токена', () async {
      final req = Request('GET', Uri.parse('http://localhost/'));
      final resp = await makeHandler(req);
      expect(resp.statusCode, 200);
    });

    for (final open in ['auth/register', 'login', 'swagger/index.html']) {
      test('открытый путь "$open" проходит без токена', () async {
        final resp = await makeHandler(makeGet(open));
        expect(resp.statusCode, 200);
      });
    }

    // ── Нет токена → 401 ─────────────────────────────────────────────────
    test('нет Authorization → 401', () async {
      final resp = await makeHandler(makeGet('protected'));
      expect(resp.statusCode, 401);
    });

    test('пустой Authorization → 401', () async {
      final resp = await makeHandler(
          makeGet('protected', headers: {'authorization': ''}));
      expect(resp.statusCode, 401);
    });

    // ── Невалидный токен → 401 ────────────────────────────────────────────
    test('Bearer garbage → 401', () async {
      final resp = await makeHandler(makeGet('protected',
          headers: {'authorization': 'Bearer not.valid.jwt'}));
      expect(resp.statusCode, 401);
    });

    // ── Валидный токен, сессии нет в репо → 401 ───────────────────────────
    test('валидный JWT но сессия не найдена → 401', () async {
      final tokens = AuthUtils.generateTokens(42, 'user');
      final resp = await makeHandler(makeGet('protected',
          headers: {'authorization': 'Bearer ${tokens['access_token']}'}));
      expect(resp.statusCode, 401);
    });

    // ── Валидный токен + подходящая сессия → 200 ──────────────────────────
    test('валидный JWT + сессия с совпадающим userId → 200', () async {
      const userId = 42;
      final bundle = AuthUtils.generateTokenBundle(userId, 'admin');
      final refreshJti = bundle['refresh_jti'] as String;
      final jtiHash = AuthUtils.hashRefreshJti(refreshJti);

      repo.stub(jtiHash, makeSession(userId: userId, refreshJtiHash: jtiHash));

      final resp = await makeHandler(makeGet('protected',
          headers: {'authorization': 'Bearer ${bundle['access_token']}'}));
      expect(resp.statusCode, 200);
    });

    // ── Токен с чужим userId → 401 ────────────────────────────────────────
    test('JWT userId не совпадает с userId сессии → 401', () async {
      final bundle = AuthUtils.generateTokenBundle(42, 'user');
      final refreshJti = bundle['refresh_jti'] as String;
      final jtiHash = AuthUtils.hashRefreshJti(refreshJti);

      // userId сессии = 99, но токен userId = 42
      repo.stub(jtiHash, makeSession(userId: 99, refreshJtiHash: jtiHash));

      final resp = await makeHandler(makeGet('protected',
          headers: {'authorization': 'Bearer ${bundle['access_token']}'}));
      expect(resp.statusCode, 401);
    });

    // ── updateLastActive вызывается при успехе ────────────────────────────
    test('успешная аутентификация → updateLastActive вызван с id сессии', () async {
      const userId = 7;
      const sessionId = 100;
      final bundle = AuthUtils.generateTokenBundle(userId, 'user');
      final jtiHash = AuthUtils.hashRefreshJti(bundle['refresh_jti'] as String);

      repo.stub(jtiHash, makeSession(id: sessionId, userId: userId, refreshJtiHash: jtiHash));
      await makeHandler(makeGet('protected',
          headers: {'authorization': 'Bearer ${bundle['access_token']}'}));

      expect(repo.updatedSessionIds, contains(sessionId));
    });

    // ── Payload помещается в контекст ─────────────────────────────────────
    test('payload пользователя доступен в request.context[user]', () async {
      const userId = 5;
      Map<String, dynamic>? capturedUser;

      final captureHandler = SecurityMiddleware.checkJWT(repo, openPaths: ['auth', 'login'])(
        (req) async {
          capturedUser = req.context['user'] as Map<String, dynamic>?;
          return Response.ok('ok');
        },
      );

      final bundle = AuthUtils.generateTokenBundle(userId, 'partner');
      final jtiHash = AuthUtils.hashRefreshJti(bundle['refresh_jti'] as String);
      repo.stub(jtiHash, makeSession(userId: userId, refreshJtiHash: jtiHash));

      await captureHandler(makeGet('protected',
          headers: {'authorization': 'Bearer ${bundle['access_token']}'}));

      expect(capturedUser, isNotNull);
      expect(capturedUser!['id'], equals(userId));
      expect(capturedUser!['role'], equals('partner'));
    });
  });
}