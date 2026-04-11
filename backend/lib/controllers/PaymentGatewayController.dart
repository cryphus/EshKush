import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../model/enums/PaymentMethod.dart';
import '../services/PaymentGatewayService.dart';
import '../services/YooKassaService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class PaymentGatewayController {
  final PaymentGatewayService _gatewayService;

  PaymentGatewayController(this._gatewayService);

  Router get router {
    final router = Router();
    router.post('/create', createPayment);
    router.post('/webhook', webhook);
    router.post('/refund', refund);
    return router;
  }

  Future<Response> createPayment(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final token = _requireToken(request);
      AuthUtils.verifyToken(token);

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: requestId);

      final data = jsonDecode(raw) as Map<String, dynamic>;
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
      );

      final body = jsonEncode(result.toJson());
      final response = Response.ok(body, headers: _corsHeaders());
      await LoggingUtils.logResponse(
          response.statusCode, response.headers, body,
          requestId: requestId);
      return response;
    } on YooKassaException catch (e) {
      await LoggingUtils.logError('Ошибка YooKassa при создании платежа', e,
          requestId: requestId);
      return Response(e.statusCode == 0 ? 502 : 502,
          body: jsonEncode({'error': e.message}), headers: _corsHeaders());
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания платежа', e,
          requestId: requestId);
      return Response(400,
          body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
          headers: _corsHeaders());
    }
  }

  Future<Response> webhook(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: requestId);

      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final sharedSecret = request.headers['x-webhook-secret'];
      await _gatewayService.handleWebhook(payload, sharedSecret: sharedSecret);
      return Response.ok(jsonEncode({'received': true}),
          headers: _corsHeaders());
    } catch (e) {
      await LoggingUtils.logError('Ошибка обработки webhook YooKassa', e,
          requestId: requestId);
      // YooKassa будет ретраить webhook при не-2xx — возвращаем 400
      // только на валидационные ошибки, чтобы избежать бесконечных ретраев.
      return Response(400,
          body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
          headers: _corsHeaders());
    }
  }

  Future<Response> refund(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      final token = _requireToken(request);
      AuthUtils.verifyToken(token);

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: requestId);

      final data = jsonDecode(raw) as Map<String, dynamic>;
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
      );

      final body = jsonEncode(saved.toJson());
      return Response.ok(body, headers: _corsHeaders());
    } on YooKassaException catch (e) {
      await LoggingUtils.logError('Ошибка YooKassa при возврате', e,
          requestId: requestId);
      return Response(502,
          body: jsonEncode({'error': e.message}), headers: _corsHeaders());
    } catch (e) {
      await LoggingUtils.logError('Ошибка возврата платежа', e,
          requestId: requestId);
      return Response(400,
          body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
          headers: _corsHeaders());
    }
  }

  String _requireToken(Request request) {
    final token = request.headers['authorization']?.replaceAll('Bearer ', '');
    if (token == null) {
      throw Exception('Требуется авторизация');
    }
    return token;
  }

  PaymentMethod _parsePaymentMethod(dynamic value) {
    if (value is! String) return PaymentMethod.card;
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.card,
    );
  }

  Response _bad(String message) => Response(400,
      body: jsonEncode({'error': message}), headers: _corsHeaders());

  Map<String, String> _corsHeaders() => {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization',
      };
}
