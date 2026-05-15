import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PaymentTransactionsController.dart';
import 'package:backend/services/PaymentTransactionsService.dart';
import 'package:backend/model/entities/PaymentTransactions.dart';
import 'package:backend/model/enums/PaymentMethod.dart';
import 'package:backend/model/enums/PaymentTransactionStatus.dart';

import 'PaymentTransactionsControllerTest.mocks.dart';

@GenerateMocks([PaymentTransactionsService])
void main() {
  late MockPaymentTransactionsService txService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    txService = MockPaymentTransactionsService();
    handler = PaymentTransactionsController(txService).router.call;
  });

  PaymentTransactions _tx({int id = 1}) => PaymentTransactions(
    id: id,
    orderId: 1,
    providerTransactionId: '100',
    orderPrice: 500.0,
    paymentMethod: PaymentMethod.card,
    status: PaymentTransactionStatus.completed,
    transactionDate: DateTime(2024),
    updatedAt: DateTime(2024),
    isActive: true,
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};
  final _authAdmin = <String, Object>{'id': 1, 'role': 'admin'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  // ── GET / (my transactions) ────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(txService.getTransactionsByUserId(1)).thenAnswer((_) async => [_tx()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /transaction ──────────────────────────────────────────────────────
  group('GET /transaction', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('transaction'));
      expect(resp.statusCode, 401);
    });

    test('400 если id не указан', () async {
      final resp = await handler(_get('transaction', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает транзакцию', () async {
      when(txService.getTransactionById(1)).thenAnswer((_) async => _tx());
      when(txService.getTransactionsByUserId(1)).thenAnswer((_) async => [_tx()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/transaction?id=1'),
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

    test('400 если user_id не указан', () async {
      final resp = await handler(_get('user', user: _authAdmin));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает транзакции пользователя', () async {
      when(txService.getTransactionsByUserId(1)).thenAnswer((_) async => [_tx()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/user?user_id=1'),
          context: _ctx(_authAdmin)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /order ────────────────────────────────────────────────────────────
  group('GET /order', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('order'));
      expect(resp.statusCode, 401);
    });

    test('400 если order_id не указан', () async {
      final resp = await handler(_get('order', user: _authAdmin));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает транзакции заказа', () async {
      when(txService.getTransactionsByOrderId(1)).thenAnswer((_) async => [_tx()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/order?order_id=1'),
          context: _ctx(_authAdmin)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /status ───────────────────────────────────────────────────────────
  group('GET /status', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('status'));
      expect(resp.statusCode, 401);
    });

    test('400 если status не указан', () async {
      final resp = await handler(_get('status', user: _authAdmin));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает транзакции по статусу', () async {
      when(txService.getTransactionsByStatus('completed')).thenAnswer((_) async => [_tx()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/status?status=completed'),
          context: _ctx(_authAdmin)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /payment-method ───────────────────────────────────────────────────
  group('GET /payment-method', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('payment-method'));
      expect(resp.statusCode, 401);
    });

    test('400 если payment_method не указан', () async {
      final resp = await handler(_get('payment-method', user: _authAdmin));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает транзакции по методу оплаты', () async {
      when(txService.getTransactionsByPaymentMethod('card'))
          .thenAnswer((_) async => [_tx()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/payment-method?payment_method=card'),
          context: _ctx(_authAdmin)));
      expect(resp.statusCode, 200);
    });
  });
}
