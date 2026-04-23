import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/OrderHistoryController.dart';
import 'package:backend/services/OrderHistoryService.dart';
import 'package:backend/model/entities/OrderHistory.dart';
import 'package:backend/model/enums/HistoryStatus.dart';

import 'OrderHistoryControllerTest.mocks.dart';

@GenerateMocks([OrderHistoryService])
void main() {
  late MockOrderHistoryService historyService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    historyService = MockOrderHistoryService();
    handler = OrderHistoryController(historyService).router.call;
  });

  OrderHistory _history({int id = 1}) => OrderHistory(
    id: id,
    orderId: 1,
    pointId: 1,
    userId: 1,
    orderDate: DateTime(2024),
    totalSum: 500.0,
    status: HistoryStatus.pending,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
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

  // ── GET / (my history) ────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает историю текущего пользователя', () async {
      when(historyService.getUserOrderHistory(1)).thenAnswer((_) async => [_history()]);
      final resp = await handler(_get('', user: _authUser));
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

    test('200 возвращает историю по id', () async {
      when(historyService.getOrderHistoryById(1)).thenAnswer((_) async => _history());
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/one?id=1'),
          context: _ctx(_authUser)));
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

    test('200 возвращает историю пользователя', () async {
      when(historyService.getUserOrderHistory(1)).thenAnswer((_) async => [_history()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/user?userId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /complete ────────────────────────────────────────────────────────
  group('POST /complete', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('complete', {'id': 1, 'totalSum': 500.0, 'co2Saved': 5}));
      expect(resp.statusCode, 401);
    });

    test('400 если отсутствуют обязательные параметры', () async {
      final resp = await handler(_post('complete', {'id': 1}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при завершении заказа', () async {
      when(historyService.completeOrder(1,
              totalSum: anyNamed('totalSum'),
              co2Saved: anyNamed('co2Saved'),
              receiptLink: anyNamed('receiptLink'),
              discountApplied: anyNamed('discountApplied'),
              promoCodeUsed: anyNamed('promoCodeUsed'),
              notes: anyNamed('notes')))
          .thenAnswer((_) async => _history());
      final resp = await handler(_post('complete', {
        'id': 1,
        'totalSum': 500.0,
        'co2Saved': 5,
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /cancel ──────────────────────────────────────────────────────────
  group('POST /cancel', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('cancel', {'id': 1, 'reason': 'Передумал'}));
      expect(resp.statusCode, 401);
    });

    test('400 если отсутствуют параметры', () async {
      final resp = await handler(_post('cancel', {'id': 1}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при отмене заказа', () async {
      when(historyService.cancelOrder(1, 'Передумал'))
          .thenAnswer((_) async => _history());
      final resp = await handler(_post('cancel', {
        'id': 1,
        'reason': 'Передумал',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-status ────────────────────────────────────────────────────────
  group('GET /by-status', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-status'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-status?status=pending'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(historyService.getOrdersByStatus(any))
          .thenAnswer((_) async => [_history()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-status?status=pending'),
          context: _ctx(_adminUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-dates ─────────────────────────────────────────────────────────
  group('GET /by-dates', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-dates'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-dates?startDate=2024-01-01&endDate=2024-12-31'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 403);
    });

    test('200 для admin с корректными датами', () async {
      when(historyService.getOrdersByDateRange(any, any))
          .thenAnswer((_) async => [_history()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-dates?startDate=2024-01-01&endDate=2024-12-31'),
          context: _ctx(_adminUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST / (create, admin) ────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'orderId': 1}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_post('', {'orderId': 1}, user: _authUser));
      expect(resp.statusCode, 403);
    });
  });
}
