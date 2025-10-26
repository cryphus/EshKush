import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/OrderHistoryService.dart';
import '../model/enums/HistoryStatus.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class OrderHistoryController {
  final OrderHistoryService _orderHistoryService;

  OrderHistoryController(this._orderHistoryService);

  Router get router {
    final router = Router();
    router.get('/one', getOrderHistory);
    router.get('/user', getUserOrderHistory);
    router.get('/point', getPointOrderHistory);
    router.post('/', createOrderHistory);
    router.post('/complete', completeOrder);
    router.post('/cancel', cancelOrder);
    router.get('/by-status', getOrdersByStatus);
    router.get('/by-dates', getOrdersByDateRange);
    return router;
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID РёСЃС‚РѕСЂРёРё Р·Р°РєР°Р·Р°');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёСЃС‚РѕСЂРёРё Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (userId == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёСЃС‚РѕСЂРёРё Р·Р°РєР°Р·РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);

      final pointId = int.tryParse(request.url.queryParameters['pointId'] ?? '');
      if (pointId == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID С‚РѕС‡РєРё');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёСЃС‚РѕСЂРёРё Р·Р°РєР°Р·РѕРІ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
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
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РёСЃС‚РѕСЂРёРё Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['totalSum'] == null || data['co2Saved'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅС‹ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїР°СЂР°РјРµС‚СЂС‹');
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
      await LoggingUtils.logError('РћС€РёР±РєР° Р·Р°РІРµСЂС€РµРЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['reason'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅС‹ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїР°СЂР°РјРµС‚СЂС‹');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕС‚РјРµРЅС‹ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final status = request.url.queryParameters['status'];
      if (status == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅ СЃС‚Р°С‚СѓСЃ');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РєР°Р·РѕРІ РїРѕ СЃС‚Р°С‚СѓСЃСѓ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final startDate = request.url.queryParameters['startDate'];
      final endDate = request.url.queryParameters['endDate'];
      if (startDate == null || endDate == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅ РґРёР°РїР°Р·РѕРЅ РґР°С‚');
      }

      if (!ValidationUtils.isValidDate(startDate) || !ValidationUtils.isValidDate(endDate)) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ РґР°С‚С‹');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РєР°Р·РѕРІ РїРѕ РґРёР°РїР°Р·РѕРЅСѓ РґР°С‚', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
