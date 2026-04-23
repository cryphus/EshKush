import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/OrderHistoryService.dart';
import '../model/enums/HistoryStatus.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class OrderHistoryController {
  final OrderHistoryService _orderHistoryService;
  late final Router _router;

  OrderHistoryController(this._orderHistoryService) {
    _router = Router();
    _router.get('/', _getMyHistory);
    _router.get('/one', getOrderHistory);
    _router.get('/user', getUserOrderHistory);
    _router.get('/point', getPointOrderHistory);
    _router.post('/', createOrderHistory);
    _router.post('/complete', completeOrder);
    _router.post('/cancel', cancelOrder);
    _router.get('/by-status', getOrdersByStatus);
    _router.get('/by-dates', getOrdersByDateRange);
  }

  Router get router => _router;

  Future<Response> _getMyHistory(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final userId = payload['id'] as int;
      final history = await _orderHistoryService.getUserOrderHistory(userId);
      return Response.ok(
        jsonEncode(history.map((o) => o.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Неверный ID истории заказа', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.getOrderHistoryById(id);
      
      final responseBody = jsonEncode(orderHistory.toJson());
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Неверный ID пользователя', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.getUserOrderHistory(userId);
      
      final responseBody = jsonEncode(orderHistory.map((o) => o.toJson()).toList());
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказов пользователя', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPointOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final pointId = int.tryParse(request.url.queryParameters['pointId'] ?? '');
      if (pointId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Неверный ID точки', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.getPointOrderHistory(pointId);
      
      final responseBody = jsonEncode(orderHistory.map((o) => o.toJson()).toList());
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказов точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> createOrderHistory(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }
      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeOrderData(data);
        final orderHistory = await _orderHistoryService.createOrderHistory(
          orderId: sanitizedData['orderId'],
          pointId: sanitizedData['pointId'],
          userId: sanitizedData['userId'],
          orderDate: DateTime.parse(sanitizedData['orderDate']),
          totalSum: (sanitizedData['totalSum'] as num?)?.toDouble() ?? 0,
          status: sanitizedData['status'] != null 
              ? HistoryStatus.values.firstWhere(
                  (e) => e.toString() == 'HistoryStatus.${sanitizedData['status']}',
                  orElse: () => HistoryStatus.pending,
                )
              : HistoryStatus.pending,
        );

        await LoggingUtils.logOrderOperation('create', orderHistory.id, sanitizedData, requestId: RequestContextUtils.getRequestId(request));
        
        final responseBody = jsonEncode(orderHistory.toJson());
        final response = Response.ok(
          responseBody,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          responseBody,
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания истории заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> completeOrder(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['totalSum'] == null || data['co2Saved'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Не указаны обязательные параметры', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.completeOrder(
        data['id'],
        totalSum: (data['totalSum'] as num).toDouble(),
        co2Saved: data['co2Saved'],
        receiptLink: data['receiptLink'],
        discountApplied: data['discountApplied'] != null 
            ? (data['discountApplied'] as num).toDouble() 
            : null,
        promoCodeUsed: data['promoCodeUsed'],
        notes: data['notes'],
      );

      await LoggingUtils.logOrderOperation('complete', orderHistory.id, data, requestId: RequestContextUtils.getRequestId(request));
      
      final response = Response.ok(
        jsonEncode(orderHistory.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(orderHistory.toJson()),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка завершения заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> cancelOrder(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['reason'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Не указаны обязательные параметры', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.cancelOrder(
        data['id'],
        data['reason'],
      );

      await LoggingUtils.logOrderOperation('cancel', orderHistory.id, data, requestId: RequestContextUtils.getRequestId(request));
      
      final response = Response.ok(
        jsonEncode(orderHistory.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(orderHistory.toJson()),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка отмены заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrdersByStatus(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final status = request.url.queryParameters['status'];
      if (status == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Не указан статус', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.getOrdersByStatus(
        HistoryStatus.values.firstWhere(
          (e) => e.toString() == 'HistoryStatus.$status',
          orElse: () => HistoryStatus.pending,
        ),
      );
      
      final response = Response.ok(
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов по статусу', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrdersByDateRange(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final startDate = request.url.queryParameters['startDate'];
      final endDate = request.url.queryParameters['endDate'];
      if (startDate == null || endDate == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Не указан диапазон дат', headers: _getCorsHeaders());
      }

      if (!ValidationUtils.isValidDate(startDate) || !ValidationUtils.isValidDate(endDate)) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный формат даты', headers: _getCorsHeaders());
      }

      final orderHistory = await _orderHistoryService.getOrdersByDateRange(
        DateTime.parse(startDate),
        DateTime.parse(endDate),
      );
      
      final response = Response.ok(
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов по диапазону дат', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }



  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
