import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/OrderHistoryService.dart';
import '../model/enums/HistoryStatus.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

class OrderHistoryController {
  final OrderHistoryService _orderHistoryService;

  OrderHistoryController(this._orderHistoryService);

  Future<Response> getOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return _createErrorResponse(400, 'Неверный ID истории заказа');
      }

      final orderHistory = await _orderHistoryService.getOrderHistoryById(id);
      
      final response = Response.ok(
        jsonEncode(orderHistory.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказа', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getUserOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null) {
        return _createErrorResponse(400, 'Неверный ID пользователя');
      }

      final orderHistory = await _orderHistoryService.getUserOrderHistory(userId);
      
      final response = Response.ok(
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказов пользователя', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getPointOrderHistory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final pointId = int.tryParse(request.url.queryParameters['pointId'] ?? '');
      if (pointId == null) {
        return _createErrorResponse(400, 'Неверный ID точки');
      }

      final orderHistory = await _orderHistoryService.getPointOrderHistory(pointId);
      
      final response = Response.ok(
        jsonEncode(orderHistory.map((o) => o.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения истории заказов точки', e);
      return _createErrorResponse(400, 'Ошибка: $e');
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
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
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

        await LoggingUtils.logOrderOperation('create', orderHistory.id, sanitizedData);
        
        final response = Response.ok(
          jsonEncode(orderHistory.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          await response.readAsString(),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания истории заказа', e);
      return _createErrorResponse(400, 'Ошибка: $e');
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
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['totalSum'] == null || data['co2Saved'] == null) {
        return _createErrorResponse(400, 'Не указаны обязательные параметры');
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

      await LoggingUtils.logOrderOperation('complete', orderHistory.id, data);
      
      final response = Response.ok(
        jsonEncode(orderHistory.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка завершения заказа', e);
      return _createErrorResponse(400, 'Ошибка: $e');
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
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['reason'] == null) {
        return _createErrorResponse(400, 'Не указаны обязательные параметры');
      }

      final orderHistory = await _orderHistoryService.cancelOrder(
        data['id'],
        data['reason'],
      );

      await LoggingUtils.logOrderOperation('cancel', orderHistory.id, data);
      
      final response = Response.ok(
        jsonEncode(orderHistory.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка отмены заказа', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getOrdersByStatus(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final status = request.url.queryParameters['status'];
      if (status == null) {
        return _createErrorResponse(400, 'Не указан статус');
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
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов по статусу', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getOrdersByDateRange(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final startDate = request.url.queryParameters['startDate'];
      final endDate = request.url.queryParameters['endDate'];
      if (startDate == null || endDate == null) {
        return _createErrorResponse(400, 'Не указан диапазон дат');
      }

      if (!ValidationUtils.isValidDate(startDate) || !ValidationUtils.isValidDate(endDate)) {
        return _createErrorResponse(400, 'Некорректный формат даты');
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
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения заказов по диапазону дат', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
  }

  Response _createErrorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: _getCorsHeaders(),
    );
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }
} 