import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ActionLogController.dart';
import 'package:backend/services/ActionLogService.dart';
import 'package:backend/model/entities/ActionLog.dart';
import 'package:backend/model/enums/ActionType.dart';
import 'package:backend/model/enums/EntityType.dart';

import 'ActionLogControllerTest.mocks.dart';

@GenerateMocks([ActionLogService])
void main() {
  late MockActionLogService logService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    logService = MockActionLogService();
    handler = ActionLogController(logService).router.call;
  });

  ActionLog _log({int id = 1}) => ActionLog(
    id: id,
    userId: 1,
    actionType: ActionType.create,
    targetEntity: EntityType.other,
    targetId: 1,
    details: 'test action',
    timestamp: DateTime(2024),
    ipAddress: '127.0.0.1',
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

  // ── GET / (recent) ────────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(logService.getRecentLogs(limit: anyNamed('limit')))
          .thenAnswer((_) async => [_log()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /user ─────────────────────────────────────────────────────────────
  group('GET /user', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('user'));
      expect(resp.statusCode, 401);
    });

    test('400 если userId не указан', () async {
      final resp = await handler(_get('user', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает логи пользователя', () async {
      when(logService.getUserLogs(1)).thenAnswer((_) async => [_log()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/user?userId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /entity ───────────────────────────────────────────────────────────
  group('GET /entity', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('entity'));
      expect(resp.statusCode, 401);
    });

    test('400 если entityId не указан', () async {
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/entity?entityType=user'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает логи сущности', () async {
      when(logService.getEntityLogs(any, 1)).thenAnswer((_) async => [_log()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/entity?entityType=other&entityId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /action-type ──────────────────────────────────────────────────────
  group('GET /action-type', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('action-type'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает логи по типу действия', () async {
      when(logService.getActionTypeLogs(any)).thenAnswer((_) async => [_log()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/action-type?actionType=create'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /log ─────────────────────────────────────────────────────────────
  group('POST /log', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('log', {'userId': 1}));
      expect(resp.statusCode, 401);
    });

    test('400 если отсутствуют обязательные поля', () async {
      final resp = await handler(_post('log', {'userId': 1}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при создании лога', () async {
      when(logService.logAction(
        userId: anyNamed('userId'),
        actionType: anyNamed('actionType'),
        targetEntity: anyNamed('targetEntity'),
        targetId: anyNamed('targetId'),
        details: anyNamed('details'),
        ipAddress: anyNamed('ipAddress'),
        userAgent: anyNamed('userAgent'),
        location: anyNamed('location'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) async => _log());
      final resp = await handler(_post('log', {
        'userId': 1,
        'actionType': 'create',
        'targetEntity': 'other',
        'targetId': 1,
        'details': 'test',
        'ipAddress': '127.0.0.1',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
