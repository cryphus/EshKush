import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProfileService.dart';
import '../model/entities/Profile.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

class ProfileController {
  final ProfileService _profileService;
  final Router _router = Router();

  ProfileController(this._profileService) {
    _router.get('/', _getProfile);
    _router.get('/<id>', _getProfileById);
    _router.post('/', _createProfile);
    _router.put('/<id>', _updateProfile);
    _router.delete('/', _deleteProfile);
  }

  Router get router => _router;

  Future<Response> _getProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final profile = await _profileService.getProfile(payload['id']);

      if (profile == null) {
        return Response(404, 
          body: jsonEncode({'error': 'Профиль не найден'}),
          headers: _getCorsHeaders(),
        );
      }

      final responseBody = jsonEncode(profile.toJson());
      final response = Response.ok(
        responseBody,
        headers: {
          ..._getCorsHeaders(),
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения профиля', e);
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getProfileById(Request request, String id) async {
    try {
      print('Получен запрос на получение профиля по ID: $id');
      
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      print('Токен авторизации: ${token != null ? 'присутствует' : 'отсутствует'}');
      
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final profile = await _profileService.getProfileById(int.parse(id));
      print('Профиль найден: ${profile != null}');

      if (profile == null) {
        return Response(404, 
          body: jsonEncode({'error': 'Профиль не найден'}),
          headers: _getCorsHeaders(),
        );
      }

      final responseBody = jsonEncode(profile.toJson());
      final response = Response.ok(
        responseBody,
        headers: {
          ..._getCorsHeaders(),
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
      );

      return response;
    } catch (e) {
      print('Ошибка при получении профиля по ID: $e');
      await LoggingUtils.logError('Ошибка получения профиля по ID', e);
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createProfile(Request request) async {
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
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      SafeLoggingUtils.logData('Данные для создания профиля', data);
      print('Тип first_name: ${data['first_name'].runtimeType}');
      print('Тип last_name: ${data['last_name'].runtimeType}');
      
      final now = DateTime.now();
      final profile = Profile(
        id: 0,
        userId: payload['id'],
        firstName: data['first_name']?.toString() ?? '',
        lastName: data['last_name']?.toString() ?? '',
        avatarUrl: data['avatar_url']?.toString(),
        bio: data['bio']?.toString(),
        sumCO2: data['sum_co2'] is String ? int.parse(data['sum_co2']) : (data['sum_co2'] as num?)?.toInt() ?? 0,
        savedMoney: data['saved_money'] is String ? double.parse(data['saved_money']) : (data['saved_money'] as num?)?.toDouble() ?? 0.0,
        countBuy: data['count_buy'] is String ? int.parse(data['count_buy']) : (data['count_buy'] as num?)?.toInt() ?? 0,
        createdAt: now,
        updatedAt: now,
      );

      final createdProfile = await _profileService.createProfile(profile);
      final responseBody = jsonEncode(createdProfile.toJson());

        final response = Response.ok(
        responseBody,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
        responseBody,
        );

        return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания профиля', e);
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка создания профиля: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _updateProfile(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      final sanitizedData = ValidationUtils.validateAndSanitizeProfileData(data);
      
      final profile = Profile(
        id: int.parse(id),
        userId: payload['id'],
        firstName: sanitizedData['first_name'] ?? '',
        lastName: sanitizedData['last_name'] ?? '',
        avatarUrl: sanitizedData['avatar_url'],
        bio: sanitizedData['bio'],
        sumCO2: 0, // Значение по умолчанию
        savedMoney: 0.0, // Значение по умолчанию
        countBuy: 0, // Значение по умолчанию
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final updatedProfile = await _profileService.update(profile);
      return Response.ok(
        jsonEncode(updatedProfile.toJson()),
        headers: {
          ..._getCorsHeaders(),
          'Content-Type': 'application/json; charset=utf-8',
        },
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка обновления профиля: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deleteProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
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
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка удаления профиля: $e'}),
      headers: _getCorsHeaders(),
    );
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }
}