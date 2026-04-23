import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerStatisticsService.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class PartnerStatisticsController {
  final PartnerStatisticsService _statisticsService;

  late final Router _router;

  PartnerStatisticsController(this._statisticsService) {
    _router = Router();
    _router.get('/', _getAll);
    _router.get('/one', getStatistics);
    _router.get('/by-partner', getPartnerStatistics);
    _router.get('/by-point', getPointStatistics);
    _router.post('/', createStatistics);
    _router.post('/update', updateStatistics);
    _router.post('/add-order', addOrder);
    _router.post('/add-cancel', addCancel);
    _router.post('/update-rating', updateRating);
  }

  Router get router => _router;

  Future<Response> _getAll(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      return Response.ok(
        jsonEncode({'message': 'Use /by-partner?partner_id=X, /by-point?point_id=X, or /one?id=X'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getStatistics(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', headers: _getCorsHeaders());
      }

      final statistics = await _statisticsService.getStatisticsById(id);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPartnerStatistics(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final partnerId = int.tryParse(request.url.queryParameters['partner_id'] ?? '');
      
      if (partnerId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID партнера', headers: _getCorsHeaders());
      }

      final statistics = await _statisticsService.getStatisticsByPartnerId(partnerId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики партнёра', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPointStatistics(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final pointId = int.tryParse(request.url.queryParameters['point_id'] ?? '');
      
      if (pointId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }

      final statistics = await _statisticsService.getStatisticsByPointId(pointId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> createStatistics(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      final statistics = await _statisticsService.createStatistics(data);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateStatistics(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', headers: _getCorsHeaders());
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final statistics = await _statisticsService.updateStatistics(id, data);
      
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> addOrder(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['id'] == null || data['revenue'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отсутствуют обязательные поля', headers: _getCorsHeaders());
      }

      await _statisticsService.addOrder(data['id'], data['revenue'].toDouble());
      final body = jsonEncode({'message': 'Заказ добавлен в статистику'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка добавления заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> addCancel(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['id'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отсутствует ID статистики', headers: _getCorsHeaders());
      }

      await _statisticsService.addCancel(data['id']);
      final body = jsonEncode({'message': 'Отмена добавлена в статистику'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка добавления отмены', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateRating(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['id'] == null || data['rating'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отсутствуют обязательные поля', headers: _getCorsHeaders());
      }

      await _statisticsService.updateRating(data['id'], data['rating'].toDouble());
      final body = jsonEncode({'message': 'Рейтинг обновлен'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления рейтинга', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
