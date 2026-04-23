import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ErrorLogsController.dart';
import 'package:backend/services/ErrorLogsService.dart';
import 'package:backend/model/entities/ErrorLogs.dart';
import 'package:backend/model/enums/ErrorSeverity.dart';

import 'ErrorLogsControllerTest.mocks.dart';

@GenerateMocks([ErrorLogsService])
void main() {
  late MockErrorLogsService errorService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    errorService = MockErrorLogsService();
    handler = ErrorLogsController(errorService).router.call;
  });

  ErrorLogs _error({int id = 1}) => ErrorLogs(
    id: id,
    errorMessage: 'Test error',
    errorCode: 'ERR_001',
    stackTrace: '#0 main()',
    time: DateTime(2024),
    severity: ErrorSeverity.high,
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
      when(errorService.getRecentErrors(limit: anyNamed('limit')))
          .thenAnswer((_) async => [_error()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /severity ─────────────────────────────────────────────────────────
  group('GET /severity', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('severity'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает ошибки по уровню', () async {
      when(errorService.getErrorsBySeverity(ErrorSeverity.high))
          .thenAnswer((_) async => [_error()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/severity?severity=high'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /module ───────────────────────────────────────────────────────────
  group('GET /module', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('module'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает ошибки по модулю', () async {
      when(errorService.getErrorsByModule('auth')).thenAnswer((_) async => [_error()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/module?module=auth'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /unresolved ───────────────────────────────────────────────────────
  group('GET /unresolved', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('unresolved'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает нерешённые ошибки', () async {
      when(errorService.getUnresolvedErrors()).thenAnswer((_) async => [_error()]);
      final resp = await handler(_get('unresolved', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /resolve ─────────────────────────────────────────────────────────
  group('POST /resolve', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('resolve', {}));
      expect(resp.statusCode, 401);
    });

    test('400 если errorId не указан', () async {
      final resp = await handler(_post('resolve', {}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при отметке как решённая', () async {
      when(errorService.markErrorAsResolved(1, any)).thenAnswer((_) async {});
      final resp = await handler(Request('POST',
          Uri.parse('http://localhost/resolve?errorId=1&resolvedBy=admin'),
          body: '',
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /log ─────────────────────────────────────────────────────────────
  group('POST /log', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('log', {'errorMessage': 'err'}));
      expect(resp.statusCode, 401);
    });

    test('400 если отсутствуют обязательные поля', () async {
      final resp = await handler(_post('log', {'errorMessage': 'err'}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при записи ошибки', () async {
      when(errorService.logError(
        errorMessage: anyNamed('errorMessage'),
        errorCode: anyNamed('errorCode'),
        stackTrace: anyNamed('stackTrace'),
        severity: anyNamed('severity'),
        module: anyNamed('module'),
        userId: anyNamed('userId'),
        additionalInfo: anyNamed('additionalInfo'),
      )).thenAnswer((_) async => _error());
      final resp = await handler(_post('log', {
        'errorMessage': 'Test error',
        'errorCode': 'ERR_001',
        'stackTrace': '#0 main()',
        'severity': 'high',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
