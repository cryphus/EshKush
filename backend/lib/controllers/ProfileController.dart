import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/ProfileService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

class ProfileController {
  final ProfileService _profileService;

  ProfileController(this._profileService);

  Future<Response> getProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final profile = await _profileService.getProfileById(payload['id']);

      final response = Response.ok(
        jsonEncode({
          'id': profile.id,
          'userId': profile.userId,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'sumCO2': profile.sumCO2,
          'createdAt': profile.createdAt.toIso8601String(),
          'updatedAt': profile.updatedAt.toIso8601String(),
        }),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения профиля', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> updateProfile(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeProfileData(data);
        if (sanitizedData['id'] != null && sanitizedData['id'] != payload['id']) {
          return _createErrorResponse(403, 'Нет прав на изменение этого профиля');
        }

        final profile = await _profileService.updateProfile(payload['id'], sanitizedData);

        await LoggingUtils.logInfo(
          'Обновлен профиль',
          context: {
            'profileId': profile.id,
            'userId': profile.userId,
          },
        );

        final response = Response.ok(
          jsonEncode({
            'id': profile.id,
            'userId': profile.userId,
            'savedMoney': profile.savedMoney,
            'countBuy': profile.countBuy,
            'sumCO2': profile.sumCO2,
            'createdAt': profile.createdAt.toIso8601String(),
            'updatedAt': profile.updatedAt.toIso8601String(),
          }),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          await response.readAsString(),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления профиля', e);
      return _createErrorResponse(400, 'Ошибка обновления профиля: $e');
    }
  }

  Future<Response> deleteProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      await _profileService.deleteProfile(payload['id']);

      await LoggingUtils.logInfo(
        'Удален профиль',
        context: {'userId': payload['id']},
      );

      final response = Response.ok(
        jsonEncode({'message': 'Профиль успешно удален'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления профиля', e);
      return _createErrorResponse(400, 'Ошибка удаления профиля: $e');
    }
  }

  Response _createErrorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: _getCorsHeaders(),
    );
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