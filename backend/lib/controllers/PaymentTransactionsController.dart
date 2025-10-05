import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PaymentTransactionsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

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
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final transaction = await _transactionsService.getTransactionById(id);
      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакции', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакции: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserTransactions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['user_id'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID пользователя'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByUserId(userId);
      final body = jsonEncode(transactions.map((t) => t.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакций пользователя', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакций пользователя: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrderTransactions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final orderId = int.tryParse(request.url.queryParameters['order_id'] ?? '');
      
      if (orderId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID заказа'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByOrderId(orderId);
      final body = jsonEncode(transactions.map((t) => t.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакций заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакций заказа: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> createTransaction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
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
      await LoggingUtils.logError('Ошибка создания транзакции', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка создания транзакции: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateTransaction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final transaction = await _transactionsService.updateTransaction(id, data);
      
      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления транзакции', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка обновления транзакции: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByDateRange(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
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
      
      final body = jsonEncode(transactions.map((t) => t.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакций по датам', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакций по датам: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByStatus(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final status = request.url.queryParameters['status'];
      
      if (status == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Статус не указан'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByStatus(status);
      final body = jsonEncode(transactions.map((t) => t.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакций по статусу', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакций по статусу: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getTransactionsByPaymentMethod(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final paymentMethod = request.url.queryParameters['payment_method'];
      
      if (paymentMethod == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Метод оплаты не указан'}),
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService.getTransactionsByPaymentMethod(
        paymentMethod,
      );
      final body = jsonEncode(transactions.map((t) => t.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакций по методу оплаты', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения транзакций по методу оплаты: $e'}), headers: _getCorsHeaders());
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