import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/UserSessionService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../middleware/SecurityMiddleware.dart';
import '../utils/RequestBodyUtils.dart';

class UserSessionController {
  final UserSessionService _sessionService;
  final Router _router = Router();

  UserSessionController(this._sessionService);

  Router get router => _router
    ..get('/', getUserSessions)
    ..get('/current', getSession)
    ..post('/', createSession)
    ..post('/terminate', terminateSession)
    ..post('/terminate-all', terminateAllSessions)
    ..post('/extend', extendSession);

  Future<Response> getSession(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final session =
          await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Активная сессия не найдена',
            code: ErrorCode.notFound,
            headers: _getCorsHeaders());
      }

      final body = jsonEncode(session.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка сессий', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserSessions(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final sessions = await _sessionService.getUserSessions(payload['id']);

      final body = jsonEncode(sessions.map((s) => s.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка сессий', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> createSession(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final token =
          request.headers['authorization']?.replaceAll('Bearer ', '') ?? '';
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      final data = RequestBodyUtils.decodeJsonObject(body);
      final refreshJti = payload['rtj']?.toString() ?? '';
      if (refreshJti.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Требуется refresh jti',
            code: ErrorCode.unauthorized,
            headers: _getCorsHeaders());
      }
      final session = await _sessionService.createSession(
        userId: payload['id'],
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: SecurityMiddleware.extractClientIp(request),
        deviceId: data['device_id'],
        location: data['location'],
        token: token,
        refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
      );

      final out = jsonEncode(session.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания сессии', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> terminateSession(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final session =
          await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Активная сессия не найдена',
            code: ErrorCode.notFound,
            headers: _getCorsHeaders());
      }
      await _sessionService.terminateSession(session);

      final body = jsonEncode({'message': 'Сессия завершена'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка завершения сессии', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> terminateAllSessions(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      await _sessionService.terminateAllUserSessions(payload['id']);

      final body = jsonEncode({'message': 'Все сессии завершены'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка завершения всех сессий', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> extendSession(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      final data = RequestBodyUtils.decodeJsonObject(body);

      if (data['duration'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указана длительность продления',
            headers: _getCorsHeaders());
      }

      final session =
          await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Активная сессия не найдена',
            code: ErrorCode.notFound,
            headers: _getCorsHeaders());
      }
      await _sessionService.extendSession(
          session, Duration(days: data['duration'] as int));

      final out = jsonEncode({'message': 'Сессия продлена'});
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка продления сессии', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
