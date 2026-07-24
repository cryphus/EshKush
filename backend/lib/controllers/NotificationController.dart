import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../model/enums/NotificationType.dart';
import '../services/NotificationService.dart';
import '../utils/AppException.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestBodyUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';

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
    // REST-вариант того же действия — его использует фронтенд.
    _router.put('/<id>/read', markAsReadByPath);
    _router.post('/sent', markAsSent);
  }

  Router get router => _router;

  Future<Response> getUserNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final hasQueryUserId = request.url.queryParameters.containsKey('userId');
      final queryUserId =
          int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (hasQueryUserId && queryUserId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID пользователя',
          headers: _getCorsHeaders(),
        );
      }

      final elevated = _isElevated(request);
      if (!elevated && queryUserId != null && queryUserId != requestUserId) {
        return _forbidden();
      }

      final targetUserId = elevated ? (queryUserId ?? requestUserId) : requestUserId;
      final notifications = await _service.getUserNotifications(targetUserId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
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
        'Ошибка получения уведомлений пользователя',
        e,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getNotificationsByType(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final type = request.url.queryParameters['type'] ?? '';
      if (type.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Не указан тип уведомления',
          headers: _getCorsHeaders(),
        );
      }

      final notificationType = NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () =>
            throw const BadRequestException('Неизвестный тип уведомления'),
      );

      final notifications = _isElevated(request)
          ? await _service.getNotificationsByType(notificationType)
          : await _service.getUserNotificationsByType(
              requestUserId,
              notificationType,
            );
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
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
        'Ошибка получения уведомлений по типу',
        e,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUnreadNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final hasQueryUserId = request.url.queryParameters.containsKey('userId');
      final queryUserId =
          int.tryParse(request.url.queryParameters['userId'] ?? '');
      if (hasQueryUserId && queryUserId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID пользователя',
          headers: _getCorsHeaders(),
        );
      }

      final elevated = _isElevated(request);
      if (!elevated && queryUserId != null && queryUserId != requestUserId) {
        return _forbidden();
      }

      final targetUserId = elevated ? (queryUserId ?? requestUserId) : requestUserId;
      final notifications = await _service.getUnreadNotifications(targetUserId);
      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
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
        'Ошибка получения непрочитанных уведомлений',
        e,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getRecentNotifications(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final notifications = _isElevated(request)
          ? await _service.getRecentNotifications(limit: limit)
          : (await _service.getUserNotifications(requestUserId))
              .take(limit)
              .toList();

      final body = jsonEncode(notifications.map((n) => n.toJson()).toList());
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
        'Ошибка получения последних уведомлений',
        e,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createNotification(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final data = await RequestBodyUtils.readJsonObject(request);
      final sanitized =
          ValidationUtils.validateAndSanitizeNotificationData(data);
      if (!_isElevated(request) && sanitized['userId'] != requestUserId) {
        return _forbidden();
      }

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
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  /// PUT /notifications/<id>/read — отметить прочитанным по id из пути.
  Future<Response> markAsReadByPath(Request request, String id) async {
    return _markAsReadById(request, int.tryParse(id));
  }

  Future<Response> markAsRead(Request request) async {
    final notificationId =
        int.tryParse(request.url.queryParameters['notificationId'] ?? '');
    return _markAsReadById(request, notificationId);
  }

  Future<Response> _markAsReadById(Request request, int? notificationId) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      if (notificationId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID уведомления',
          headers: _getCorsHeaders(),
        );
      }

      if (!_isElevated(request)) {
        final isOwner = await _service.isNotificationOwnedByUser(
          notificationId: notificationId,
          userId: requestUserId,
        );
        if (!isOwner) return _forbidden();
      }

      await _service.markNotificationAsRead(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как прочитанное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markAsSent(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(
        request,
        headers: _getCorsHeaders(),
      );
      if (unauthorized != null) return unauthorized;

      final requestUserId = RequestContextUtils.getUserId(request);
      if (requestUserId == null) return _forbidden();

      final notificationId =
          int.tryParse(request.url.queryParameters['notificationId'] ?? '');
      if (notificationId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Некорректный ID уведомления',
          headers: _getCorsHeaders(),
        );
      }

      if (!_isElevated(request)) {
        final isOwner = await _service.isNotificationOwnedByUser(
          notificationId: notificationId,
          userId: requestUserId,
        );
        if (!isOwner) return _forbidden();
      }

      await _service.markNotificationAsSent(notificationId);
      return Response.ok(
        jsonEncode({'message': 'Уведомление отмечено как отправленное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
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
