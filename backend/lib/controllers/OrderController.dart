import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/OrderService.dart';
import '../services/PaymentGatewayService.dart';
import '../services/YooKassaService.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../model/dto/responses/OrderResponseDto.dart';
import '../model/dto/requests/CreateOrderDto.dart';
import 'dart:convert';

class OrderController {
  final OrderService _orderService;
  final PaymentGatewayService? _paymentGatewayService;

  OrderController(
    this._orderService, {
    PaymentGatewayService? paymentGatewayService,
  }) : _paymentGatewayService = paymentGatewayService;

  Router get router {
    final router = Router();

    router.get('/', _getAllOrders);
    router.get('/<id>', _getOrderById);
    router.get('/user/<userId>', _getUserOrders);
    router.post('/', _createOrder);
    router.put('/<id>/status', _updateOrderStatus);
    router.post('/<id>/refund', _refundOrder);
    router.delete('/<id>', _deleteOrder);

    return router;
  }

  Future<Response> _refundOrder(Request request) async {
    final requestId = RequestContextUtils.getRequestId(request);
    try {
      if (_paymentGatewayService == null) {
        return Response(503,
            body: jsonEncode({'error': 'Платёжный шлюз не сконфигурирован'}),
            headers: _getCorsHeaders());
      }

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response.unauthorized(
            jsonEncode({'error': 'Требуется авторизация'}),
            headers: _getCorsHeaders());
      }
      final payload = AuthUtils.verifyToken(token);
      final userId = payload['id'] as int;

      final orderId = int.parse(request.params['id']!);
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: requestId);

      Map<String, dynamic> data = const {};
      if (raw.isNotEmpty) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      }

      final amount = data['amount'] == null
          ? null
          : double.tryParse(data['amount'].toString());

      final transaction = await _paymentGatewayService!.refund(
        orderId: orderId,
        amount: amount,
        description: data['description'] as String?,
        requestingUserId: userId,
      );

      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: requestId);
      return resp;
    } on RefundException catch (e) {
      await LoggingUtils.logError('Отказ в возврате', e, requestId: requestId);
      return Response(409,
          body: jsonEncode({'error': e.message}), headers: _getCorsHeaders());
    } on YooKassaException catch (e) {
      await LoggingUtils.logError('YooKassa отклонила возврат', e,
          requestId: requestId);
      return Response(502,
          body: jsonEncode({'error': e.message}), headers: _getCorsHeaders());
    } catch (e) {
      await LoggingUtils.logError('Ошибка возврата заказа', e,
          requestId: requestId);
      return Response.badRequest(
          body: jsonEncode(
              {'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _getAllOrders(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final status = request.url.queryParameters['status'];
      final orders = await _orderService.getAllOrders(
        status: status != null ? OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
          orElse: () => OrderStatus.pending,
        ) : null,
      );

      final body = jsonEncode(orders.map((o) => OrderResponseDto.fromEntity(o).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РєР°Р·РѕРІ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.internalServerError(body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getOrderById(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final id = int.parse(request.params['id']!);
      final order = await _orderService.getOrderById(id);
      final orderDto = OrderResponseDto.fromEntity(order);
      final body = jsonEncode(orderDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Р—Р°РєР°Р· РЅРµ РЅР°Р№РґРµРЅ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.notFound(jsonEncode({'error': 'Р—Р°РєР°Р· РЅРµ РЅР°Р№РґРµРЅ'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getUserOrders(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final userId = int.parse(request.params['userId']!);
      final orders = await _orderService.getUserOrders(userId);
      final body = jsonEncode(orders.map((o) => OrderResponseDto.fromEntity(o).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РєР°Р·РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _createOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          jsonEncode({'error': 'РќРµРѕР±С…РѕРґРёРјР° Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, SafeLoggingUtils.sanitizeString(data), requestId: RequestContextUtils.getRequestId(request));
      try {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        
        final createDto = CreateOrderDto.fromJson(jsonData);
        final order = await _orderService.createOrder(createDto.toEntityData());
        
        final orderDto = OrderResponseDto.fromEntity(order);
        final body = jsonEncode(orderDto.toJson());
        final resp = Response.ok(body, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } on ValidationException catch (e) {
        return Response.badRequest(
          body: jsonEncode({'error': e.message}), 
          headers: _getCorsHeaders(),
        );
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateOrderStatus(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'РќРµРѕР±С…РѕРґРёРјР° Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      final data = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, data, requestId: RequestContextUtils.getRequestId(request));
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      final status = OrderStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == jsonData['status'].toString().toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
      
      final order = await _orderService.updateOrderStatus(id, status);
      final orderDto = OrderResponseDto.fromEntity(order);
      final body = jsonEncode(orderDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃС‚Р°С‚СѓСЃР° Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'РќРµРѕР±С…РѕРґРёРјР° Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final id = int.parse(request.params['id']!);
      await _orderService.deleteOrder(id);
      final body = jsonEncode({'message': 'Р—Р°РєР°Р· СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<bool> _isAuthorized(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null) return false;

    try {
      final token = authHeader.split(' ').last;
      AuthUtils.verifyToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
      'Content-Type': 'application/json',
    };
  }
} 
