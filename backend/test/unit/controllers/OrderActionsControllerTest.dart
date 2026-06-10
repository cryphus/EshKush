import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/OrderActionsController.dart';
import 'package:backend/services/OrderActionsService.dart';
import 'package:backend/model/entities/OrderActions.dart';
import 'package:backend/model/enums/ActionType.dart';

import 'OrderActionsControllerTest.mocks.dart';

@GenerateMocks([OrderActionsService])
void main() {
  late MockOrderActionsService actionsService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    actionsService = MockOrderActionsService();
    handler = OrderActionsController(actionsService).router.call;
  });

  OrderActions _action({int id = 1}) => OrderActions(
    id: id,
    orderId: 1,
    actionType: ActionType.create,
    description: 'Test action',
    createdAt: DateTime(2024),
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};
  final _adminUser = <String, Object>{'id': 1, 'role': 'admin'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  // ── GET / (active, admin only) ────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(actionsService.getActiveActions()).thenAnswer((_) async => [_action()]);
      final resp = await handler(_get('', user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /one ──────────────────────────────────────────────────────────────
  group('GET /one', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('one'));
      expect(resp.statusCode, 401);
    });

    test('400 если id не указан', () async {
      final resp = await handler(_get('one', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает действие', () async {
      when(actionsService.getActionById(1)).thenAnswer((_) async => _action());
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/one?id=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-order ─────────────────────────────────────────────────────────
  group('GET /by-order', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-order'));
      expect(resp.statusCode, 401);
    });

    test('400 если orderId не указан', () async {
      final resp = await handler(_get('by-order', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает действия заказа', () async {
      when(actionsService.getOrderActions(1)).thenAnswer((_) async => [_action()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-order?orderId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-partner ───────────────────────────────────────────────────────
  group('GET /by-partner', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-partner'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-partner?partnerId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(actionsService.getPartnerActions(1)).thenAnswer((_) async => [_action()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-partner?partnerId=1'),
          context: _ctx(_adminUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST / (create) ───────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'orderId': 1, 'partnerId': 1}));
      expect(resp.statusCode, 401);
    });

    test('200 при создании действия', () async {
      when(actionsService.createAction(
        orderId: anyNamed('orderId'),
        partnerId: anyNamed('partnerId'),
        actionDescription: anyNamed('actionDescription'),
        actionType: anyNamed('actionType'),
      )).thenAnswer((_) async => _action());
      final resp = await handler(_post('', {
        'orderId': 1,
        'partnerId': 1,
        'actionDescription': 'Test',
        'actionType': 'create',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /deactivate ──────────────────────────────────────────────────────
  group('POST /deactivate', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('deactivate', {'id': 1}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_post('deactivate', {'id': 1}, user: _authUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(actionsService.deactivateAction(1)).thenAnswer((_) async => _action());
      final resp = await handler(_post('deactivate', {'id': 1}, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /activate ────────────────────────────────────────────────────────
  group('POST /activate', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('activate', {'id': 1}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_post('activate', {'id': 1}, user: _authUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(actionsService.activateAction(1)).thenAnswer((_) async => _action());
      final resp = await handler(_post('activate', {'id': 1}, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /update-type ─────────────────────────────────────────────────────
  group('POST /update-type', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('update-type', {'id': 1, 'actionType': 'update'}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(
          _post('update-type', {'id': 1, 'actionType': 'update'}, user: _authUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(actionsService.updateActionType(1, any)).thenAnswer((_) async => _action());
      final resp = await handler(
          _post('update-type', {'id': 1, 'actionType': 'update'}, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });
}
