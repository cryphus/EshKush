import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/UserSessionService.dart';
import '../utils/AuthUtils.dart';

class UserSessionController {
  final UserSessionService _sessionService;

  UserSessionController(this._sessionService);

  Future<Response> getSession(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final session = await _sessionService.getSessionById(payload['sessionId']);

      return Response.ok(
        jsonEncode(session.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUserSessions(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final sessions = await _sessionService.getUserSessions(payload['id']);

      return Response.ok(
        jsonEncode(sessions.map((s) => s.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createSession(Request request) async {
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
      
      final session = await _sessionService.createSession(
        userId: payload['id'],
        userAgent: request.headers['user-agent'] ?? '',
        ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? '',
        deviceId: data['device_id'],
        location: data['location'],
        token: token,
      );

      return Response.ok(
        jsonEncode(session.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> terminateSession(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final session = await _sessionService.getSessionById(payload['sessionId']);
      await _sessionService.terminateSession(session);

      return Response.ok(
        jsonEncode({'message': 'Сессия завершена'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> terminateAllSessions(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      await _sessionService.terminateAllUserSessions(payload['id']);

      return Response.ok(
        jsonEncode({'message': 'Все сессии завершены'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> extendSession(Request request) async {
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
      
      if (data['duration'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Не указана длительность продления'}),
          headers: _getCorsHeaders(),
        );
      }

      final session = await _sessionService.getSessionById(payload['sessionId']);
      await _sessionService.extendSession(
        session, 
        Duration(days: data['duration'] as int),
      );

      return Response.ok(
        jsonEncode({'message': 'Сессия продлена'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
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