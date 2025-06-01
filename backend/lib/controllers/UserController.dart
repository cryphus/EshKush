import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/UserService.dart';
import '../utils/AuthUtils.dart';

class UserController {
  final UserService _userService;

  UserController(this._userService);

  Future<Response> getProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final user = await _userService.getUserById(payload['id']);

      return Response.ok(
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.created_at.toIso8601String(),
        }),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateProfile(Request request) async {
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

      return Response.ok(
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.created_at.toIso8601String(),
        }),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка обновления профиля: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> addToFavorites(Request request) async {
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
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный идентификатор точки'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.addToFavorites(payload['id'], data['point_id']);
      return Response.ok(
        jsonEncode({'message': 'Точка добавлена в избранное'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
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
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный идентификатор точки'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.removeFromFavorites(payload['id'], data['point_id']);
      return Response.ok(
        jsonEncode({'message': 'Точка удалена из избранного'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateBalance(Request request) async {
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
      
      if (data['amount'] == null || data['amount'].abs() > 1000000) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректная сумма'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.updateBalance(payload['id'], data['amount']);
      return Response.ok(
        jsonEncode({'message': 'Баланс обновлен'}),
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

  bool _validateUpdateData(Map<String, dynamic> data) {
    if (data['email'] != null && !RegExp(r'^.+@.+\..+$').hasMatch(data['email'])) {
      return false;
    }
    if (data['number'] != null && !RegExp(r'^\+\d{11,14}').hasMatch(data['number'])) {
      return false;
    }
    if (data['username'] != null && (data['username'] as String).isEmpty) {
      return false;
    }
    return true;
  }
} 