import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerStatisticsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class PartnerStatisticsController {
  final PartnerStatisticsService _statisticsService;

  PartnerStatisticsController(this._statisticsService);

  Router get router {
    final router = Router();
    router.get('/one', getStatistics);
    router.get('/by-partner', getPartnerStatistics);
    router.get('/by-point', getPointStatistics);
    router.post('/', createStatistics);
    router.post('/update', updateStatistics);
    router.post('/add-order', addOrder);
    router.post('/add-cancel', addCancel);
    router.post('/update-rating', updateRating);
    return router;
  }

  Future<Response> getStatistics(Request request) async {
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

      final statistics = await _statisticsService.getStatisticsById(id);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения статистики: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPartnerStatistics(Request request) async {
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
      final partnerId = int.tryParse(request.url.queryParameters['partner_id'] ?? '');
      
      if (partnerId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID партнера'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPartnerId(partnerId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики партнера', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения статистики партнера: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPointStatistics(Request request) async {
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
      final pointId = int.tryParse(request.url.queryParameters['point_id'] ?? '');
      
      if (pointId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID точки'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPointId(pointId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики точки', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка получения статистики точки: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> createStatistics(Request request) async {
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
      
      final statistics = await _statisticsService.createStatistics(data);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка создания статистики: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateStatistics(Request request) async {
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
      final statistics = await _statisticsService.updateStatistics(id, data);
      
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления статистики', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка обновления статистики: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addOrder(Request request) async {
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
      
      if (data['id'] == null || data['revenue'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addOrder(data['id'], data['revenue'].toDouble());
      final body = jsonEncode({'message': 'Заказ добавлен в статистику'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка добавления заказа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка добавления заказа: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addCancel(Request request) async {
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
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствует ID статистики'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addCancel(data['id']);
      final body = jsonEncode({'message': 'Отмена добавлена в статистику'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка добавления отмены', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка добавления отмены: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateRating(Request request) async {
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
      
      if (data['id'] == null || data['rating'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.updateRating(data['id'], data['rating'].toDouble());
      final body = jsonEncode({'message': 'Рейтинг обновлен'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления рейтинга', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка обновления рейтинга: $e'}), headers: _getCorsHeaders());
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