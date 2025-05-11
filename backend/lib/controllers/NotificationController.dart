import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/NotificationService.dart';
import '../model/enums/NotificationType.dart';

class NotificationController {
  final NotificationService _service;

  NotificationController(this._service);

  Router get router {
    final router = Router();

    router.get('/user/<userId>', _getUserNotifications);
    router.get('/type/<type>', _getNotificationsByType);
    router.get('/unread/<userId>', _getUnreadNotifications);
    router.get('/recent', _getRecentNotifications);
    router.post('/<notificationId>/read', _markAsRead);
    router.post('/<notificationId>/sent', _markAsSent);

    return router;
  }

  Future<Response> _getUserNotifications(Request request, String userId) async {
    try {
      final notifications = await _service.getUserNotifications(int.parse(userId));
      return Response.ok(
        notifications.map((n) => n.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при получении уведомлений пользователя: $e',
      );
    }
  }

  Future<Response> _getNotificationsByType(Request request, String type) async {
    try {
      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () => throw Exception('Неизвестный тип уведомления'),
      );
      
      final notifications = await _service.getNotificationsByType(notificationType);
      return Response.ok(
        notifications.map((n) => n.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при получении уведомлений по типу: $e',
      );
    }
  }

  Future<Response> _getUnreadNotifications(Request request, String userId) async {
    try {
      final notifications = await _service.getUnreadNotifications(int.parse(userId));
      return Response.ok(
        notifications.map((n) => n.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при получении непрочитанных уведомлений: $e',
      );
    }
  }

  Future<Response> _getRecentNotifications(Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final notifications = await _service.getRecentNotifications(limit: limit);
      return Response.ok(
        notifications.map((n) => n.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при получении последних уведомлений: $e',
      );
    }
  }

  Future<Response> _markAsRead(Request request, String notificationId) async {
    try {
      await _service.markNotificationAsRead(int.parse(notificationId));
      return Response.ok('Уведомление отмечено как прочитанное');
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при отметке уведомления как прочитанного: $e',
      );
    }
  }

  Future<Response> _markAsSent(Request request, String notificationId) async {
    try {
      await _service.markNotificationAsSent(int.parse(notificationId));
      return Response.ok('Уведомление отмечено как отправленное');
    } catch (e) {
      return Response.internalServerError(
        body: 'Ошибка при отметке уведомления как отправленного: $e',
      );
    }
  }
} 