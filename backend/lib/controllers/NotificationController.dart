import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/NotificationService.dart';
import '../model/enums/NotificationType.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';

class NotificationController {
  final NotificationService _service;

  NotificationController(this._service);

  Router get router {
    final router = Router();

    router.get('/user', getUserNotifications);
    router.get('/type', getNotificationsByType);
    router.get('/unread', getUnreadNotifications);
    router.get('/recent', getRecentNotifications);
    router.post('/create', createNotification);
    router.post('/read', markAsRead);
    router.post('/sent', markAsSent);

    return router;
  }

  Future<Response> getUserNotifications(Request request) async {
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
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final notifications = await _service.getUserNotifications(userId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getNotificationsByType(Request request) async {
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
      final type = request.url.queryParameters['type'] ?? '';
      
      if (type.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµ СѓРєР°Р·Р°РЅ С‚РёРї СѓРІРµРґРѕРјР»РµРЅРёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () => throw Exception('РќРµРёР·РІРµСЃС‚РЅС‹Р№ С‚РёРї СѓРІРµРґРѕРјР»РµРЅРёСЏ'),
      );
      
      final notifications = await _service.getNotificationsByType(notificationType);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕ С‚РёРїСѓ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕ С‚РёРїСѓ: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getUnreadNotifications(Request request) async {
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
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final notifications = await _service.getUnreadNotifications(userId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> getRecentNotifications(Request request) async {
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
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final notifications = await _service.getRecentNotifications(limit: limit);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕСЃР»РµРґРЅРёС… СѓРІРµРґРѕРјР»РµРЅРёР№', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё РїРѕСЃР»РµРґРЅРёС… СѓРІРµРґРѕРјР»РµРЅРёР№: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> createNotification(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      final sanitized = ValidationUtils.validateAndSanitizeNotificationData(data);

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == sanitized['type'],
        orElse: () => throw Exception('РќРµРёР·РІРµСЃС‚РЅС‹Р№ С‚РёРї СѓРІРµРґРѕРјР»РµРЅРёСЏ'),
      );

      final notification = await _service.createNotification(
        userId: sanitized['userId'],
        message: sanitized['message'],
        type: notificationType,
        metadata: sanitized['metadata'],
      );

      return Response.ok(
        jsonEncode(notification.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markAsRead(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final notificationId = int.tryParse(request.url.queryParameters['notificationId'] ?? '');
      
      if (notificationId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID СѓРІРµРґРѕРјР»РµРЅРёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      await _service.markNotificationAsRead(notificationId);
      return Response.ok(
        jsonEncode({'message': 'РЈРІРµРґРѕРјР»РµРЅРёРµ РѕС‚РјРµС‡РµРЅРѕ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРµ'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РѕС‚РјРµС‚РєРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРіРѕ: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markAsSent(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      AuthUtils.verifyToken(token);
      final notificationId = int.tryParse(request.url.queryParameters['notificationId'] ?? '');
      
      if (notificationId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID СѓРІРµРґРѕРјР»РµРЅРёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      await _service.markNotificationAsSent(notificationId);
      return Response.ok(
        jsonEncode({'message': 'РЈРІРµРґРѕРјР»РµРЅРёРµ РѕС‚РјРµС‡РµРЅРѕ РєР°Рє РѕС‚РїСЂР°РІР»РµРЅРЅРѕРµ'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РѕС‚РјРµС‚РєРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РѕС‚РїСЂР°РІР»РµРЅРЅРѕРіРѕ: $e'}),
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
