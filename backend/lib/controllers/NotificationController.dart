import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/NotificationService.dart';
import '../model/enums/NotificationType.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/AppException.dart';
import '../utils/RequestBodyUtils.dart';

class NotificationController {
  final NotificationService _service;
  late final Router _router;

  NotificationController(this._service) {
    _router = Router();
    _router.get('/', getRecentNotifications);
    _router.get('/user', getUserNotifications);
    _router.get('/type', getNotificationsByType);
    _router.get('/unread', getUnreadNotifications);
    _router.get('/recent', getRecentNotifications);
    _router.post('/create', createNotification);
    _router.post('/read', markAsRead);
    _router.post('/sent', markAsSent);
  }

  Router get router => _router;

  Future<Response> getUserNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');

      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID пользователя',
            headers: _getCorsHeaders());
      }

      final notifications = await _service.getUserNotifications(userId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError(
          'Ошибка получения уведомлений пользователя', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getNotificationsByType(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final type = request.url.queryParameters['type'] ?? '';

      if (type.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указан тип уведомления',
            headers: _getCorsHeaders());
      }

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () =>
            throw const BadRequestException('Неизвестный тип уведомления'),
      );

      final notifications =
          await _service.getNotificationsByType(notificationType);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения уведомлений по типу', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getUnreadNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');

      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID пользователя',
            headers: _getCorsHeaders());
      }

      final notifications = await _service.getUnreadNotifications(userId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError(
          'Ошибка получения непрочитанных уведомлений', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getRecentNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final notifications = await _service.getRecentNotifications(limit: limit);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения последних уведомлений', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> createNotification(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = await RequestBodyUtils.readJsonObject(request);
      final sanitized =
          ValidationUtils.validateAndSanitizeNotificationData(data);

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == sanitized['type'],
        orElse: () =>
            throw const BadRequestException('Неизвестный тип уведомления'),
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
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> markAsRead(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final notificationId =
          int.tryParse(request.url.queryParameters['notificationId'] ?? '');

      if (notificationId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID уведомления',
            headers: _getCorsHeaders());
      }

      await _service.markNotificationAsRead(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как прочитанное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> markAsSent(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final notificationId =
          int.tryParse(request.url.queryParameters['notificationId'] ?? '');

      if (notificationId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID уведомления',
            headers: _getCorsHeaders());
      }

      await _service.markNotificationAsSent(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как отправленное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
