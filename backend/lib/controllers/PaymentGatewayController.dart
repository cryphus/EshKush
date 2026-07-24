import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../model/enums/PaymentMethod.dart';
import '../services/PaymentGatewayService.dart';
import '../services/YooKassaService.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/RequestBodyUtils.dart';

class PaymentGatewayController {
  final PaymentGatewayService _gatewayService;

  PaymentGatewayController(this._gatewayService);

  Router get router {
    final router = Router();
    router.post('/create', createPayment);
    router.post('/webhook', webhook);
    router.post('/refund', refund);
    router.get('/mock-checkout', mockCheckout);
    return router;
  }

  /// Страница "касса" mock-режима. Открывается вместо реальной страницы
  /// оплаты YooKassa, когда шлюз работает без боевых ключей. Платёж к этому
  /// моменту уже подтверждён, поэтому страница только информирует.
  Future<Response> mockCheckout(Request request) async {
    final orderId = request.url.queryParameters['order_id'] ?? '—';
    final amount = request.url.queryParameters['amount'] ?? '—';
    final html = '''
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Тестовая оплата — EshKush</title>
<style>
  body { font-family: system-ui, sans-serif; background: #f4f8f2; display: flex;
         align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
  .card { background: #fff; border-radius: 16px; padding: 40px 48px; text-align: center;
          box-shadow: 0 4px 24px rgba(0,0,0,.08); max-width: 420px; }
  .check { width: 72px; height: 72px; border-radius: 50%; background: #4CAF50;
           color: #fff; font-size: 40px; line-height: 72px; margin: 0 auto 20px; }
  h1 { font-size: 22px; margin: 0 0 8px; color: #1b3a1b; }
  p { color: #555; margin: 6px 0; }
  .badge { display: inline-block; margin-top: 16px; padding: 4px 12px; border-radius: 12px;
           background: #FFF3CD; color: #856404; font-size: 12px; }
</style>
</head>
<body>
  <div class="card">
    <div class="check">✓</div>
    <h1>Оплата прошла успешно</h1>
    <p>Заказ №$orderId</p>
    <p>Сумма: $amount ₽</p>
    <p>Можно вернуться в приложение — статус заказа обновится автоматически.</p>
    <div class="badge">Тестовый режим (без реального списания)</div>
  </div>
</body>
</html>''';
    return Response.ok(
      html,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Content-Security-Policy':
            "default-src 'none'; style-src 'unsafe-inline'; base-uri 'self'",
      },
    );
  }

  Future<Response> createPayment(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _corsHeaders());
      if (unauthorized != null) return unauthorized;
      final user = RequestContextUtils.getUser(request)!;
      final requestingUserId = _isElevated(request) ? null : user['id'] as int;

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: requestId,
      );

      final data = RequestBodyUtils.decodeJsonObject(raw);
      final orderId = data['order_id'];
      if (orderId is! int) {
        return _bad('order_id обязателен и должен быть числом');
      }

      final paymentMethod = _parsePaymentMethod(data['payment_method']);
      final result = await _gatewayService.initiatePayment(
        orderId: orderId,
        description: data['description'] as String?,
        returnUrl: data['return_url'] as String?,
        paymentMethod: paymentMethod,
        requestingUserId: requestingUserId,
      );

      final body = jsonEncode(result.toJson());
      final response = Response.ok(body, headers: _corsHeaders());
      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        body,
        requestId: requestId,
      );
      return response;
    } on YooKassaException catch (e) {
      await LoggingUtils.logError(
        'Ошибка YooKassa при создании платежа',
        e,
        requestId: requestId,
      );
      return Response(
        502,
        body: jsonEncode({'error': e.message}),
        headers: _corsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания платежа', e,
          requestId: requestId);
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: requestId,
        headers: _corsHeaders(),
      );
    }
  }

  Future<Response> webhook(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: requestId,
      );

      final payload = RequestBodyUtils.decodeJsonObject(raw);
      final sharedSecret = request.headers['x-webhook-secret'];
      await _gatewayService.handleWebhook(payload, sharedSecret: sharedSecret);
      return Response.ok(
        jsonEncode({'received': true}),
        headers: _corsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка обработки webhook YooKassa', e,
          requestId: requestId);
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: requestId,
        headers: _corsHeaders(),
      );
    }
  }

  Future<Response> refund(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _corsHeaders());
      if (unauthorized != null) return unauthorized;
      final user = RequestContextUtils.getUser(request)!;
      final requestingUserId = _isElevated(request) ? null : user['id'] as int;

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: requestId,
      );

      final data = RequestBodyUtils.decodeJsonObject(raw);
      final orderId = data['order_id'];
      if (orderId is! int) {
        return _bad('order_id обязателен и должен быть числом');
      }

      final amount = data['amount'] == null
          ? null
          : double.tryParse(data['amount'].toString());

      final saved = await _gatewayService.refund(
        orderId: orderId,
        amount: amount,
        description: data['description'] as String?,
        requestingUserId: requestingUserId,
      );

      final body = jsonEncode(saved.toJson());
      return Response.ok(body, headers: _corsHeaders());
    } on YooKassaException catch (e) {
      await LoggingUtils.logError('Ошибка YooKassa при возврате', e,
          requestId: requestId);
      return Response(
        502,
        body: jsonEncode({'error': e.message}),
        headers: _corsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка возврата платежа', e,
          requestId: requestId);
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: requestId,
        headers: _corsHeaders(),
      );
    }
  }

  bool _isElevated(Request request) {
    final role = RequestContextUtils.getRole(request);
    return role == 'admin' || role == 'support';
  }

  PaymentMethod _parsePaymentMethod(dynamic value) {
    if (value is! String) return PaymentMethod.card;
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.card,
    );
  }

  Response _bad(String message) => Response(
        400,
        body: jsonEncode({'error': message}),
        headers: _corsHeaders(),
      );

  Map<String, String> _corsHeaders() => {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization',
      };
}
