import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/UserService.dart';
import '../utils/auth_utils.dart';


class UserController {
  final UserService _userService;

  UserController(this._userService);

  Future<Response> getProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final user = await _userService.getUserById(payload['id']);

      return Response.ok(
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'sum_co2': user.sumCO2,
          'money': user.money,
          'role': user.role.toString(),
          'favorite_ids': user.favoriteIds,
        }),
      );
    } catch (e) {
      return Response(400, body: 'Ошибка: $e');
    }
  }

  Future<Response> updateProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      final user = await _userService.updateUser(payload['id'], data);

      return Response.ok(
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'number': user.number,
          'sum_co2': user.sumCO2,
          'money': user.money,
          'role': user.role.toString(),
        }),
      );
    } catch (e) {
      return Response(400, body: 'Ошибка обновления профиля: $e');
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      await _userService.addToFavorites(payload['id'], data['point_id']);
      return Response.ok('Точка добавлена в избранное');
    } catch (e) {
      return Response(400, body: 'Ошибка: $e');
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      await _userService.removeFromFavorites(payload['id'], data['point_id']);
      return Response.ok('Точка удалена из избранного');
    } catch (e) {
      return Response(400, body: 'Ошибка: $e');
    }
  }

  Future<Response> updateBalance(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      await _userService.updateBalance(payload['id'], data['amount']);
      return Response.ok('Баланс обновлен');
    } catch (e) {
      return Response(400, body: 'Ошибка: $e');
    }
  }
} 