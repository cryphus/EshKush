import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../model/dto/responses/PaymentTransactionDto.dart';
import '../services/PaymentGatewayService.dart';
import '../services/PaymentTransactionsService.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestBodyUtils.dart';
import '../utils/RequestContextUtils.dart';

class PaymentTransactionsController {
  final PaymentTransactionsService _transactionsService;
  final PaymentGatewayService? _gatewayService;
  late final Router _router;

  PaymentTransactionsController(this._transactionsService,
      {PaymentGatewayService? gatewayService})
      : _gatewayService = gatewayService {
    _router = Router();
    _router.get('/', _getMyTransactions);
    _router.get('/transaction', getTransaction);
    _router.get('/user', getUserTransactions);
    _router.get('/order', getOrderTransactions);
    _router.get('/date-range', getTransactionsByDateRange);
    _router.get('/status', getTransactionsByStatus);
    _router.get('/payment-method', getTransactionsByPaymentMethod);
    _router.post('/create', createTransaction);
    _router.post('/update', updateTransaction);
  }

  Router get router => _router;

  Future<Response> _getMyTransactions(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final userId = payload['id'] as int;
      final transactions =
          await _transactionsService.getTransactionsByUserId(userId);
      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
      );
      return Response.ok(body, headers: _getCorsHeaders());
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getTransaction(Request request) async {
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

      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID',
          headers: _getCorsHeaders(),
        );
      }

      final transaction = await _transactionsService.getTransactionById(id);
      if (!_isElevated(request)) {
        final requestUserId = RequestContextUtils.getUserId(request);
        if (requestUserId == null) return _forbidden();
        final accessible = await _transactionsService.isTransactionOwnedByUser(
          transactionId: transaction.id,
          userId: requestUserId,
        );
        if (!accessible) return _forbidden();
      }

      final transactionDto = PaymentTransactionDto.fromEntity(transaction);
      final body = jsonEncode(transactionDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения транзакции', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUserTransactions(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final userId = int.tryParse(request.url.queryParameters['user_id'] ?? '');
      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID пользователя',
          headers: _getCorsHeaders(),
        );
      }

      final transactions =
          await _transactionsService.getTransactionsByUserId(userId);
      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
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
      await LoggingUtils.logError('Ошибка получения транзакций пользователя', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getOrderTransactions(Request request) async {
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

      final orderId =
          int.tryParse(request.url.queryParameters['order_id'] ?? '');
      if (orderId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID заказа',
          headers: _getCorsHeaders(),
        );
      }

      // Обычный пользователь видит транзакции только своих заказов —
      // этот эндпоинт поллит фронтенд после инициации оплаты.
      if (!_isElevated(request)) {
        final requestUserId = RequestContextUtils.getUserId(request);
        if (requestUserId == null) return _forbidden();
        final owns = await _transactionsService.isOrderOwnedByUser(
          orderId: orderId,
          userId: requestUserId,
        );
        if (!owns) return _forbidden();
      }

      // Подтягиваем актуальные статусы pending-платежей у провайдера —
      // критично, когда webhook не доходит (локальная разработка).
      if (_gatewayService != null) {
        await _gatewayService!.syncPendingByOrder(orderId);
      }

      final transactions =
          await _transactionsService.getTransactionsByOrderId(orderId);
      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
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
      await LoggingUtils.logError('Ошибка получения транзакций заказа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createTransaction(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final data = RequestBodyUtils.decodeJsonObject(raw);

      final transaction = await _transactionsService.createTransaction(data);
      final body = jsonEncode(transaction.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания транзакции', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateTransaction(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID',
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        raw,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final data = RequestBodyUtils.decodeJsonObject(raw);
      final transaction =
          await _transactionsService.updateTransaction(id, data);

      final transactionDto = PaymentTransactionDto.fromEntity(transaction);
      final body = jsonEncode(transactionDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(
        resp.statusCode,
        resp.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления транзакции', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getTransactionsByDateRange(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final startDate =
          DateTime.parse(request.url.queryParameters['start_date'] ?? '');
      final endDate =
          DateTime.parse(request.url.queryParameters['end_date'] ?? '');

      final transactions = await _transactionsService
          .getTransactionsByDateRange(startDate, endDate);

      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
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
      await LoggingUtils.logError('Ошибка получения транзакций по датам', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getTransactionsByStatus(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final status = request.url.queryParameters['status'];
      if (status == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Статус не указан',
          headers: _getCorsHeaders(),
        );
      }

      final transactions =
          await _transactionsService.getTransactionsByStatus(status);
      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
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
      await LoggingUtils.logError('Ошибка получения транзакций по статусу', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getTransactionsByPaymentMethod(Request request) async {
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
      if (!_isElevated(request)) return _forbidden();

      final paymentMethod = request.url.queryParameters['payment_method'];
      if (paymentMethod == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Метод оплаты не указан',
          headers: _getCorsHeaders(),
        );
      }

      final transactions = await _transactionsService
          .getTransactionsByPaymentMethod(paymentMethod);
      final body = jsonEncode(
        transactions
            .map((t) => PaymentTransactionDto.fromEntity(t).toJson())
            .toList(),
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
      await LoggingUtils.logError(
          'Ошибка получения транзакций по методу оплаты', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  bool _isElevated(Request request) {
    final role = RequestContextUtils.getRole(request);
    return role == 'admin' || role == 'support';
  }

  Response _forbidden() => ErrorResponseUtils.errorResponseWithMessage(
        'Доступ запрещён',
        code: ErrorCode.forbidden,
        headers: _getCorsHeaders(),
      );

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
