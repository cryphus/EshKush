import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/OrderController.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/model/entities/Order.dart';
import 'package:backend/model/enums/OrderStatus.dart';

import 'OrderControllerTest.mocks.dart';

@GenerateMocks([OrderService])
void main() {
  late MockOrderService orderService;
  late Handler handler;

  setUpAll(() {
    AppConfig.initForTesting();
  });

  setUp(() {
    orderService = MockOrderService();
    handler = OrderController(orderService).router.call;
  });

  Order _order({int id = 1}) => Order(
    id: id, productsId: [1], userId: 1, pointId: 1,
    date: DateTime(2024), totalPrice: 100.0, createdAt: DateTime(2024),
  );

  Request _get(String path, {Map<String, dynamic>? user}) {
    final ctx = <String, Object>{};
    if (user != null) ctx['user'] = user;
    return Request('GET', Uri.parse('http://localhost/$path'), context: ctx);
  }

  Request _post(String path, Map<String, dynamic> body, {Map<String, dynamic>? user}) {
    final ctx = <String, Object>{};
    if (user != null) ctx['user'] = user;
    return Request(
      'POST', Uri.parse('http://localhost/$path'),
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
      context: ctx,
    );
  }

  Request _delete(String path, {Map<String, dynamic>? user}) {
    final ctx = <String, Object>{};
    if (user != null) ctx['user'] = user;
    return Request('DELETE', Uri.parse('http://localhost/$path'), context: ctx);
  }

  // ── GET / ─────────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список заказов', () async {
      when(orderService.getAllOrders(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_order(id: 1), _order(id: 2)]);

      final resp = await handler(_get('', user: {'id': 1, 'role': 'admin'}));
      expect(resp.statusCode, 200);

      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect((body['data'] as List).length, 2);
    });

    test('200 с пустым списком', () async {
      when(orderService.getAllOrders(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => []);

      final resp = await handler(_get('', user: {'id': 1, 'role': 'admin'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id> ──────────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 если заказ найден', () async {
      when(orderService.getOrderById(1)).thenAnswer((_) async => _order());

      final resp = await handler(_get('1', user: {'id': 1, 'role': 'user'}));
      expect(resp.statusCode, 200);
    });

    test('404 если заказ не найден', () async {
      when(orderService.getOrderById(99)).thenThrow(Exception('Заказ не найден'));

      final resp = await handler(_get('99', user: {'id': 1, 'role': 'user'}));
      expect(resp.statusCode, 404);
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────────
  group('POST /', () {
    final user = {'id': 1, 'role': 'user'};

    test('200 при корректных данных', () async {
      when(orderService.createOrder(any)).thenAnswer((_) async => _order());

      final resp = await handler(_post('', {
        'user_id': 1, 'point_id': 1,
        'products_id': [1], 'total_price': 100.0,
      }, user: user));

      expect(resp.statusCode, 200);
    });

    test('401 без аутентификации', () async {
      final resp = await handler(_post('', {
        'user_id': 1, 'point_id': 1,
        'products_id': [1], 'total_price': 100.0,
      }));
      expect(resp.statusCode, 401);
    });

    test('400/422 при невалидных данных (пустой products_id)', () async {
      final resp = await handler(_post('', {
        'user_id': 1, 'point_id': 1,
        'products_id': [], 'total_price': 100.0,
      }, user: user));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── DELETE /<id> ───────────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    final admin = {'id': 1, 'role': 'admin'};

    test('200 при успешном удалении', () async {
      when(orderService.deleteOrder(1)).thenAnswer((_) async {});

      final resp = await handler(_delete('1', user: admin));
      expect(resp.statusCode, 200);
    });

    test('4xx если заказ не найден', () async {
      when(orderService.deleteOrder(99)).thenThrow(Exception('Заказ не найден'));

      final resp = await handler(_delete('99', user: admin));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── PUT /<id>/status ────────────────────────────────────────────────────────
  group('PUT /<id>/status', () {
    final admin = {'id': 1, 'role': 'admin'};

    test('200 при смене статуса', () async {
      when(orderService.updateOrderStatus(1, OrderStatus.completed))
          .thenAnswer((_) async => _order());

      final req = Request(
        'PUT', Uri.parse('http://localhost/1/status'),
        body: jsonEncode({'status': 'completed'}),
        headers: {'content-type': 'application/json'},
        context: {'user': admin},
      );
      final resp = await handler(req);
      expect(resp.statusCode, 200);
    });
  });
}
