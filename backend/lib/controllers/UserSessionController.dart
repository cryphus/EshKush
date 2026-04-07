import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/UserSessionService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

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
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final session = await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Активная сессия не найдена', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      final body = jsonEncode(session.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка сессий', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserSessions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final sessions = await _sessionService.getUserSessions(payload['id']);

      final body = jsonEncode(sessions.map((s) => s.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРёСЃРєР° СЃРµСЃСЃРёР№', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> createSession(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final token = request.headers['authorization']?.replaceAll('Bearer ', '') ?? '';
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      final refreshJti = payload['rtj']?.toString() ?? '';
      if (refreshJti.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage('Требуется refresh jti', code: ErrorCode.unauthorized, headers: _getCorsHeaders());
      }
      final session = await _sessionService.createSession(
        userId: payload['id'],
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
        deviceId: data['device_id'],
        location: data['location'],
        token: token,
        refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
      );

      final out = jsonEncode(session.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРµСЃСЃРёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> terminateSession(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final session = await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Активная сессия не найдена', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }
      await _sessionService.terminateSession(session);

      final body = jsonEncode({'message': 'РЎРµСЃСЃРёСЏ Р·Р°РІРµСЂС€РµРЅР°'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° Р·Р°РІРµСЂС€РµРЅРёСЏ СЃРµСЃСЃРёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> terminateAllSessions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      await _sessionService.terminateAllUserSessions(payload['id']);

      final body = jsonEncode({'message': 'Р’СЃРµ СЃРµСЃСЃРёРё Р·Р°РІРµСЂС€РµРЅС‹'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° Р·Р°РІРµСЂС€РµРЅРёСЏ РІСЃРµС… СЃРµСЃСЃРёР№', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> extendSession(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      
      if (data['duration'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Не указана длительность продления', headers: _getCorsHeaders());
      }

      final session = await _sessionService.getCurrentActiveSessionForUser(payload['id']);
      if (session == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Активная сессия не найдена', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }
      await _sessionService.extendSession(session, Duration(days: data['duration'] as int));

      final out = jsonEncode({'message': 'РЎРµСЃСЃРёСЏ РїСЂРѕРґР»РµРЅР°'});
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїСЂРѕРґР»РµРЅРёСЏ СЃРµСЃСЃРёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
