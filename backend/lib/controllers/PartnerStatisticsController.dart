import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerStatisticsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

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

      final statistics = await _statisticsService.getStatisticsById(id);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPartnerStatistics(Request request) async {
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
      final partnerId = int.tryParse(request.url.queryParameters['partner_id'] ?? '');
      
      if (partnerId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїР°СЂС‚РЅРµСЂР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPartnerId(partnerId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР°СЂС‚РЅРµСЂР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getPointStatistics(Request request) async {
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
      final pointId = int.tryParse(request.url.queryParameters['point_id'] ?? '');
      
      if (pointId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPointId(pointId);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> createStatistics(Request request) async {
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
      
      final statistics = await _statisticsService.createStatistics(data);
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateStatistics(Request request) async {
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
      final statistics = await _statisticsService.updateStatistics(id, data);
      
      final body = jsonEncode(statistics.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addOrder(Request request) async {
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
      
      if (data['id'] == null || data['revenue'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓСЋС‚ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addOrder(data['id'], data['revenue'].toDouble());
      final body = jsonEncode({'message': 'Р—Р°РєР°Р· РґРѕР±Р°РІР»РµРЅ РІ СЃС‚Р°С‚РёСЃС‚РёРєСѓ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addCancel(Request request) async {
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
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓРµС‚ ID СЃС‚Р°С‚РёСЃС‚РёРєРё'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addCancel(data['id']);
      final body = jsonEncode({'message': 'РћС‚РјРµРЅР° РґРѕР±Р°РІР»РµРЅР° РІ СЃС‚Р°С‚РёСЃС‚РёРєСѓ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РѕС‚РјРµРЅС‹', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateRating(Request request) async {
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
      
      if (data['id'] == null || data['rating'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓСЋС‚ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.updateRating(data['id'], data['rating'].toDouble());
      final body = jsonEncode({'message': 'Р РµР№С‚РёРЅРі РѕР±РЅРѕРІР»РµРЅ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЂРµР№С‚РёРЅРіР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
