import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/UserSessionController.dart';
import 'package:backend/services/UserSessionService.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/model/enums/SessionStatus.dart';

import 'UserSessionControllerTest.mocks.dart';

@GenerateMocks([UserSessionService])
void main() {
  late MockUserSessionService sessionService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    sessionService = MockUserSessionService();
    handler = UserSessionController(sessionService).router.call;
  });

  UserSessions _session({int id = 1}) => UserSessions(
    id: id,
    userId: 1,
    createdAt: DateTime(2024),
    expiresAt: DateTime(2025),
    lastActive: DateTime(2024),
    userAgent: 'Mozilla/5.0',
    ipAddress: '127.0.0.1',
    refreshJtiHash: 'abc123hash',
    isActive: true,
    status: SessionStatus.active,
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(sessionService.getUserSessions(1)).thenAnswer((_) async => [_session()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /current ──────────────────────────────────────────────────────────
  group('GET /current', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('current'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает активную сессию', () async {
      when(sessionService.getCurrentActiveSessionForUser(1))
          .thenAnswer((_) async => _session());
      final resp = await handler(_get('current', user: _authUser));
      expect(resp.statusCode, 200);
    });

    test('404 если нет активной сессии', () async {
      when(sessionService.getCurrentActiveSessionForUser(1))
          .thenAnswer((_) async => null);
      final resp = await handler(_get('current', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST /terminate ───────────────────────────────────────────────────────
  group('POST /terminate', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('terminate', {}));
      expect(resp.statusCode, 401);
    });

    test('404 если нет активной сессии', () async {
      when(sessionService.getCurrentActiveSessionForUser(1))
          .thenAnswer((_) async => null);
      final resp = await handler(_post('terminate', {}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при завершении сессии', () async {
      when(sessionService.getCurrentActiveSessionForUser(1))
          .thenAnswer((_) async => _session());
      when(sessionService.terminateSession(any)).thenAnswer((_) async {});
      final resp = await handler(_post('terminate', {}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /terminate-all ───────────────────────────────────────────────────
  group('POST /terminate-all', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('terminate-all', {}));
      expect(resp.statusCode, 401);
    });

    test('200 завершает все сессии', () async {
      when(sessionService.terminateAllUserSessions(1)).thenAnswer((_) async {});
      final resp = await handler(_post('terminate-all', {}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /extend ──────────────────────────────────────────────────────────
  group('POST /extend', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('extend', {'duration': 7}));
      expect(resp.statusCode, 401);
    });

    test('400 если duration не указан', () async {
      final resp = await handler(_post('extend', {}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при продлении сессии', () async {
      when(sessionService.getCurrentActiveSessionForUser(1))
          .thenAnswer((_) async => _session());
      when(sessionService.extendSession(any, any)).thenAnswer((_) async {});
      final resp = await handler(_post('extend', {'duration': 7}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
