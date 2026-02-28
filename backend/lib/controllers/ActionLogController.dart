import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ActionLogService.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class ActionLogController {
  final ActionLogService _service;

  ActionLogController(this._service);

  Router get router {
    final router = Router();
    router.get('/user', getUserLogs);
    router.get('/entity', getEntityLogs);
    router.get('/action-type', getActionTypeLogs);
    router.get('/recent', getRecentLogs);
    router.post('/log', logAction);
    return router;
  }

  Future<Response> getUserLogs(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final logs = await _service.getUserLogs(userId);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getEntityLogs(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final entityType = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['entityType'],
        orElse: () => EntityType.other,
      );
      final entityId = int.tryParse(request.url.queryParameters['entityId'] ?? '');
      
      if (entityId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID СЃСѓС‰РЅРѕСЃС‚Рё'}),
          headers: _getCorsHeaders(),
        );
      }
      
      final logs = await _service.getEntityLogs(entityType, entityId);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getActionTypeLogs(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final actionType = ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['actionType'],
        orElse: () => ActionType.other,
      );
      
      final logs = await _service.getActionTypeLogs(actionType);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getRecentLogs(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final logs = await _service.getRecentLogs(limit: limit);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> logAction(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['userId'] == null || data['actionType'] == null || 
          data['targetEntity'] == null || data['targetId'] == null ||
          data['details'] == null || data['ipAddress'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓСЋС‚ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final actionType = ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['actionType'],
        orElse: () => ActionType.other,
      );
      
      final targetEntity = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['targetEntity'],
        orElse: () => EntityType.other,
      );

      final log = await _service.logAction(
        userId: data['userId'],
        actionType: actionType,
        targetEntity: targetEntity,
        targetId: data['targetId'],
        details: data['details'],
        ipAddress: data['ipAddress'],
        userAgent: data['userAgent'],
        location: data['location'],
        metadata: data['metadata'],
      );

      return Response.ok(
        jsonEncode(log.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
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
