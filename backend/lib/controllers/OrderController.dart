import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/OrderService.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/PaginationUtils.dart';
import '../model/dto/responses/OrderResponseDto.dart';
import '../model/dto/requests/CreateOrderDto.dart';
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
      final pagination = PaginationUtils.parse(request);
      final status = request.url.queryParameters['status'];
      final orders = await _orderService.getAllOrders(
        status: status != null ? OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
          orElse: () => OrderStatus.pending,
        ) : null,
        limit: pagination.limit,
        offset: pagination.offset,
      );

      final body = jsonEncode(PaginationUtils.wrap(
        orders.map((o) => OrderResponseDto.fromEntity(o).toJson()).toList(),
        pagination,
      ));
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
      await LoggingUtils.logError('Заказ не найден', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponseWithMessage('Заказ не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _createOrder(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

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
        return ErrorResponseUtils.errorResponseWithMessage(e.message, code: ErrorCode.validationError, headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateOrderStatus(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

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
      await LoggingUtils.logError('Ошибка получения списка сессий', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteOrder(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final id = int.parse(request.params['id']!);
      await _orderService.deleteOrder(id);
      final body = jsonEncode({'message': 'Заказ успешно удалён'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
