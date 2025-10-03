import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/NotificationService.dart';
import '../model/enums/NotificationType.dart';
import '../utils/AuthUtils.dart';

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
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID пользователя'}),
          headers: _getCorsHeaders(),
        );
      }

      final notifications = await _service.getUserNotifications(userId);
      return Response.ok(
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при получении уведомлений пользователя: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getNotificationsByType(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final type = request.url.queryParameters['type'] ?? '';
      
      if (type.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'Не указан тип уведомления'}),
          headers: _getCorsHeaders(),
        );
      }

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () => throw Exception('Неизвестный тип уведомления'),
      );
      
      final notifications = await _service.getNotificationsByType(notificationType);
      return Response.ok(
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при получении уведомлений по типу: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUnreadNotifications(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID пользователя'}),
          headers: _getCorsHeaders(),
        );
      }

      final notifications = await _service.getUnreadNotifications(userId);
      return Response.ok(
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при получении непрочитанных уведомлений: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getRecentNotifications(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final notifications = await _service.getRecentNotifications(limit: limit);
      return Response.ok(
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при получении последних уведомлений: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createNotification(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['userId'] == null || data['message'] == null || data['type'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == data['type'],
        orElse: () => throw Exception('Неизвестный тип уведомления'),
      );

      final notification = await _service.createNotification(
        userId: data['userId'],
        message: data['message'],
        type: notificationType,
        metadata: data['metadata'],
      );

      return Response.ok(
        jsonEncode(notification.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка создания уведомления: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markAsRead(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final notificationId = int.tryParse(request.url.queryParameters['notificationId'] ?? '');
      
      if (notificationId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID уведомления'}),
          headers: _getCorsHeaders(),
        );
      }

      await _service.markNotificationAsRead(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как прочитанное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при отметке уведомления как прочитанного: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markAsSent(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final notificationId = int.tryParse(request.url.queryParameters['notificationId'] ?? '');
      
      if (notificationId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID уведомления'}),
          headers: _getCorsHeaders(),
        );
      }

      await _service.markNotificationAsSent(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как отправленное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка при отметке уведомления как отправленного: $e'}),
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