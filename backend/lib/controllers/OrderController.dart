import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/OrderService.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';
import 'dart:convert';

class OrderController {
  final OrderService _orderService;

  OrderController(this._orderService);

  Router get router {
    final router = Router();

    router.get('/', _getAllOrders);
    router.get('/<id>', _getOrderById);
    router.get('/user/<userId>', _getUserOrders);
    router.post('/', _createOrder);
    router.put('/<id>/status', _updateOrderStatus);
    router.delete('/<id>', _deleteOrder);

    return router;
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

      final body = jsonEncode(orders.map((o) => o.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getOrderById(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final id = int.parse(request.params['id']!);
      final order = await _orderService.getOrderById(id);
      final body = jsonEncode(order.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Заказ не найден', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.notFound(jsonEncode({'error': 'Заказ не найден'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getUserOrders(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final userId = int.parse(request.params['userId']!);
      final orders = await _orderService.getUserOrders(userId);
      final body = jsonEncode(orders.map((o) => o.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов пользователя', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': e.toString()}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _createOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          jsonEncode({'error': 'Необходима авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, SafeLoggingUtils.sanitizeString(data), requestId: RequestContextUtils.getRequestId(request));
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      final sanitized = ValidationUtils.validateAndSanitizeOrderCreateData(jsonData);
      final order = await _orderService.createOrder(sanitized);
      final body = jsonEncode(order.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': e.toString()}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateOrderStatus(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
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
      final body = jsonEncode(order.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления статуса заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': e.toString()}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final id = int.parse(request.params['id']!);
      await _orderService.deleteOrder(id);
      final body = jsonEncode({'message': 'Заказ успешно удален'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response.badRequest(body: jsonEncode({'error': e.toString()}), headers: _getCorsHeaders());
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