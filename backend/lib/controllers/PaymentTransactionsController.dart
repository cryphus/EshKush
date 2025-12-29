import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PaymentTransactionsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/PaymentTransactionDto.dart';

class PaymentTransactionsController {
  final PaymentTransactionsService _transactionsService;

  PaymentTransactionsController(this._transactionsService);

  Router get router {
    final router = Router();

    router.get('/transaction', getTransaction);
    router.get('/user', getUserTransactions);
    router.get('/order', getOrderTransactions);
    router.get('/date-range', getTransactionsByDateRange);
    router.get('/status', getTransactionsByStatus);
    router.get('/payment-method', getTransactionsByPaymentMethod);
    router.post('/create', createTransaction);
    router.post('/update', updateTransaction);

    return router;
  }

  Future<Response> getTransaction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final transaction = await _transactionsService.getTransactionById(id);
      final transactionDto = PaymentTransactionDto.fromEntity(transaction);
      final body = jsonEncode(transactionDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserTransactions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['user_id'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByUserId(userId);
      final body = jsonEncode(transactions.map((t) => PaymentTransactionDto.fromEntity(t).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrderTransactions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final orderId = int.tryParse(request.url.queryParameters['order_id'] ?? '');
      
      if (orderId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID Р·Р°РєР°Р·Р°'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByOrderId(orderId);
      final body = jsonEncode(transactions.map((t) => PaymentTransactionDto.fromEntity(t).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ Р·Р°РєР°Р·Р°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> createTransaction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      final transaction = await _transactionsService.createTransaction(data);
      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateTransaction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final transaction = await _transactionsService.updateTransaction(id, data);
      
      final transactionDto = PaymentTransactionDto.fromEntity(transaction);
      final body = jsonEncode(transactionDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёРё: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByDateRange(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final startDate = DateTime.parse(request.url.queryParameters['start_date'] ?? '');
      final endDate = DateTime.parse(request.url.queryParameters['end_date'] ?? '');
      
      final transactions = await _transactionsService.getTransactionsByDateRange(
        startDate,
        endDate,
      );
      
      final body = jsonEncode(transactions.map((t) => PaymentTransactionDto.fromEntity(t).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ РґР°С‚Р°Рј', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ РґР°С‚Р°Рј: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByStatus(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final status = request.url.queryParameters['status'];
      
      if (status == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РЎС‚Р°С‚СѓСЃ РЅРµ СѓРєР°Р·Р°РЅ'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByStatus(status);
      final body = jsonEncode(transactions.map((t) => PaymentTransactionDto.fromEntity(t).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ СЃС‚Р°С‚СѓСЃСѓ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ СЃС‚Р°С‚СѓСЃСѓ: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByPaymentMethod(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final paymentMethod = request.url.queryParameters['payment_method'];
      
      if (paymentMethod == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РњРµС‚РѕРґ РѕРїР»Р°С‚С‹ РЅРµ СѓРєР°Р·Р°РЅ'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByPaymentMethod(
        paymentMethod,
      );
      final body = jsonEncode(transactions.map((t) => PaymentTransactionDto.fromEntity(t).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ РјРµС‚РѕРґСѓ РѕРїР»Р°С‚С‹', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№ РїРѕ РјРµС‚РѕРґСѓ РѕРїР»Р°С‚С‹: $e'}), headers: _getCorsHeaders());
    }
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
