import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/UserService.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class UserController {
  final UserService _userService;
  final Router _router = Router();

  UserController(this._userService) {
    _router.get('/profile', _getProfile);
    _router.put('/profile', _updateProfile);
  }

  Router get router => _router;

  Future<Response> _getProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final user = await _userService.getUserById(payload['id']);

      final body = jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.createdAt.toIso8601String(),
        });
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения профиля пользователя', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final payload = AuthUtils.verifyToken(token);

      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, SafeLoggingUtils.sanitizeString(body), requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      SafeLoggingUtils.logData('Данные для обновления', data);
      
      if (!_validateUpdateData(data)) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректные данные'}),
          headers: _getCorsHeaders(),
        );
      }

      if (data['id'] != null && data['id'] != payload['id']) {
        return Response(403, 
          body: jsonEncode({'error': 'Нет прав на изменение этого профиля'}),
          headers: _getCorsHeaders(),
        );
      }

      final user = await _userService.updateUser(payload['id'], data);
      final bodyOut = jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.createdAt.toIso8601String(),
        });
      final resp = Response.ok(bodyOut, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, bodyOut, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления профиля', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка обновления профиля: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный идентификатор точки'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.addToFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'Точка добавлена в избранное'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный идентификатор точки'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.removeFromFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'Точка удалена из избранного'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateBalance(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['amount'] == null || data['amount'].abs() > 1000000) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректная сумма'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.updateBalance(payload['id'], data['amount']);
      final body = jsonEncode({'message': 'Баланс обновлен'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
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

  bool _validateUpdateData(Map<String, dynamic> data) {
    if (data['email'] != null && !RegExp(r'^.+@.+\..+$').hasMatch(data['email'])) {
      return false;
    }
    if (data['number'] != null && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(data['number'])) {
      return false;
    }
    if (data['username'] != null && (data['username'] as String).isEmpty) {
      return false;
    }
    return true;
  }
} 