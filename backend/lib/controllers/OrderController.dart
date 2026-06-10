import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../model/dto/requests/CreateOrderDto.dart';
import '../model/dto/responses/OrderResponseDto.dart';
import '../model/enums/OrderStatus.dart';
import '../services/OrderService.dart';
import '../services/PaymentGatewayService.dart';
import '../services/YooKassaService.dart';
import '../utils/AppException.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/PaginationUtils.dart';
import '../utils/RequestBodyUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/SafeLoggingUtils.dart';

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
        return Response(
          503,
          body: jsonEncode({'error': 'Платежный шлюз не сконфигурирован'}),
          headers: _getCorsHeaders(),
        );
      }

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = RequestContextUtils.getUser(request)!['id'] as int;

      final orderId = int.tryParse(request.params['id'] ?? '');
      if (orderId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID заказа',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: requestId,
      );

      Map<String, dynamic> data = const {};
      if (raw.isNotEmpty) {
        data = RequestBodyUtils.decodeJsonObject(raw);
      }

      final amount = data['amount'] == null
          ? null
          : double.tryParse(data['amount'].toString());

      final transaction = await _paymentGatewayService!.refund(
        orderId: orderId,
        amount: amount,
        description: data['description'] as String?,
        requestingUserId: _isElevated(request) ? null : userId,
      );

      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: requestId,
      );
      return resp;
    } on YooKassaException catch (e) {
      await LoggingUtils.logError('YooKassa отклонила возврат', e,
          requestId: requestId);
      return Response(
        502,
        body: jsonEncode({'error': e.message}),
        headers: _getCorsHeaders(),
      );
    } on AppException catch (e) {
      await LoggingUtils.logError('Отказ в возврате', e, requestId: requestId);
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: requestId,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка возврата заказа', e,
          requestId: requestId);
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: requestId,
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getAllOrders(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется авторизация',
          code: ErrorCode.unauthorized,
          headers: _getCorsHeaders(),
        );
      }

      if (!_isElevated(request)) {
        final ownOrders = await _orderService.getUserOrders(requestUserId);
        final ownBody = jsonEncode(
          ownOrders
              .map((o) => OrderResponseDto.fromEntity(o).toJson())
              .toList(),
        );
        final ownResp = Response.ok(ownBody, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(
          ownResp.statusCode,
          ownResp.headers,
          ownBody,
          requestId: RequestContextUtils.getRequestId(request),
        );
        return ownResp;
      }

      final pagination = PaginationUtils.parse(request);
      final status = request.url.queryParameters['status'];
      final orders = await _orderService.getAllOrders(
        status: status != null
            ? OrderStatus.values.firstWhere(
                (e) => e.name.toLowerCase() == status.toLowerCase(),
                orElse: () => OrderStatus.pending,
              )
            : null,
        limit: pagination.limit,
        offset: pagination.offset,
      );

      final body = jsonEncode(PaginationUtils.wrap(
        orders.map((o) => OrderResponseDto.fromEntity(o).toJson()).toList(),
        pagination,
      ));
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getOrderById(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID заказа',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }

      final order = await _orderService.getOrderById(id);
      if (!_isElevated(request)) {
        final requestUserId = RequestContextUtils.getUserId(request);
        if (requestUserId == null || order.userId != requestUserId) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Доступ запрещён',
            code: ErrorCode.forbidden,
            headers: _getCorsHeaders(),
          );
        }
      }

      final orderDto = OrderResponseDto.fromEntity(order);
      final body = jsonEncode(orderDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Заказ не найден', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponseWithMessage(
        'Заказ не найден',
        code: ErrorCode.notFound,
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getUserOrders(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

      final pathUserId = int.tryParse(request.params['userId'] ?? '');
      if (pathUserId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID пользователя',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }

      final requestUserId = RequestContextUtils.getUserId(request);
      if (!_isElevated(request) && requestUserId != pathUserId) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Доступ запрещён',
          code: ErrorCode.forbidden,
          headers: _getCorsHeaders(),
        );
      }

      final orders = await _orderService.getUserOrders(pathUserId);
      final body = jsonEncode(
        orders.map((o) => OrderResponseDto.fromEntity(o).toJson()).toList(),
      );
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов пользователя', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _createOrder(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется авторизация',
          code: ErrorCode.unauthorized,
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        SafeLoggingUtils.sanitizeString(data),
        requestId: RequestContextUtils.getRequestId(request),
      );

      try {
        final jsonData = RequestBodyUtils.decodeJsonObject(data);
        final createDto = CreateOrderDto.fromJson(jsonData);
        final createData = createDto.toEntityData();
        if (!_isElevated(request)) {
          createData['user_id'] = requestUserId;
        }

        final order = await _orderService.createOrder(createData);
        final orderDto = OrderResponseDto.fromEntity(order);
        final body = jsonEncode(orderDto.toJson());
        final resp = Response.ok(body, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(
          resp.statusCode,
          resp.headers,
          body,
          requestId: RequestContextUtils.getRequestId(request),
        );
        return resp;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponseWithMessage(
          e.message,
          code: ErrorCode.validationError,
          headers: _getCorsHeaders(),
        );
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания заказа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateOrderStatus(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!_isElevated(request)) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Недостаточно прав для изменения статуса заказа',
          code: ErrorCode.forbidden,
          headers: _getCorsHeaders(),
        );
      }

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID заказа',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        data,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final jsonData = RequestBodyUtils.decodeJsonObject(data);
      final rawStatus = jsonData['status']?.toString().toLowerCase() ?? '';
      final statusMatch = OrderStatus.values.where(
        (e) => e.name.toLowerCase() == rawStatus,
      );
      if (statusMatch.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Неверный статус заказа: "$rawStatus". Допустимые значения: ${OrderStatus.values.map((e) => e.name).join(', ')}',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }
      final status = statusMatch.first;

      final order = await _orderService.updateOrderStatus(id, status);
      final orderDto = OrderResponseDto.fromEntity(order);
      final body = jsonEncode(orderDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления статуса заказа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteOrder(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!_isElevated(request)) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Недостаточно прав для удаления заказа',
          code: ErrorCode.forbidden,
          headers: _getCorsHeaders(),
        );
      }

      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID заказа',
          code: ErrorCode.badRequest,
          headers: _getCorsHeaders(),
        );
      }
      await _orderService.deleteOrder(id);
      final body = jsonEncode({'message': 'Заказ успешно удалён'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления заказа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }

  bool _isElevated(Request request) {
    final role = RequestContextUtils.getRole(request);
    return role == 'admin' || role == 'support';
  }
}
