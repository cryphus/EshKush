import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/ProfileService.dart';
import '../utils/AuthUtils.dart';

class ProfileController {
  final ProfileService _profileService;

  ProfileController(this._profileService);

  Future<Response> getProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final profile = await _profileService.getProfileById(payload['id']);

      return Response.ok(
        jsonEncode({
          'id': profile.id,
          'userId': profile.userId,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'sumCO2': profile.sumCO2,
          'createdAt': profile.createdAt.toIso8601String(),
          'updatedAt': profile.updatedAt.toIso8601String(),
        }),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
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
      if (data['id'] != null && data['id'] != payload['id']) {
        return Response(403, body: 'Нет прав на изменение этого профиля');
      }
      final profile = await _profileService.updateProfile(payload['id'], data);

      return Response.ok(
        jsonEncode({
          'id': profile.id,
          'userId': profile.userId,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'sumCO2': profile.sumCO2,
          'createdAt': profile.createdAt.toIso8601String(),
          'updatedAt': profile.updatedAt.toIso8601String(),
        }),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      return Response(400, body: 'Ошибка обновления профиля');
    }
  }

  Future<Response> deleteProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      await _profileService.deleteProfile(payload['id']);
      return Response.ok('Профиль удалён');
    } catch (e) {
      return Response(400, body: 'Ошибка удаления профиля');
    }
  }
}