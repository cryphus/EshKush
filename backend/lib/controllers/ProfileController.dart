import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProfileService.dart';
import '../model/entities/Profile.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/ProfileResponseDto.dart';
import '../model/dto/requests/CreateProfileDto.dart';
import '../utils/ErrorResponseUtils.dart';

class ProfileController {
  final ProfileService _profileService;
  final Router _router = Router();

  ProfileController(this._profileService) {
    _router.get('/', _getProfile);
    // Специальный алиас для текущего пользователя: /profiles/me
    _router.get('/me', _getProfile);
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final profile = await _profileService.getProfile(payload['id']);

      if (profile == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      final profileDto = ProfileResponseDto.fromEntity(profile);
      final responseBody = jsonEncode(profileDto.toJson());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getProfileById(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;

      final profile = await _profileService.getProfileById(int.parse(id));
      await LoggingUtils.logInfo('Р РµР·СѓР»СЊС‚Р°С‚ РїРѕРёСЃРєР° РїСЂРѕС„РёР»СЏ', context: {'found': profile != null}, requestId: RequestContextUtils.getRequestId(request));

      if (profile == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      final profileDto = ProfileResponseDto.fromEntity(profile);
      final responseBody = jsonEncode(profileDto.toJson());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РїРѕ ID', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final data = jsonDecode(body) as Map<String, dynamic>;
      data['user_id'] = payload['id'];
      SafeLoggingUtils.logData('Данные для создания профиля', data);

      final createDto = CreateProfileDto.fromJson(data);
      
      final now = DateTime.now();
      final profile = Profile(
        id: 0,
        userId: payload['id'],
        firstName: createDto.firstName,
        lastName: createDto.lastName,
        avatarUrl: createDto.avatarUrl,
        bio: createDto.bio,
        sumCO2: 0,
        savedMoney: 0.0,
        countBuy: 0,
        createdAt: now,
        updatedAt: now,
      );

      final createdProfile = await _profileService.createProfile(profile);
      
      final profileDto = ProfileResponseDto.fromEntity(createdProfile);
      final responseBody = jsonEncode(profileDto.toJson());

        final response = Response.ok(
        responseBody,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания профиля', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateProfile(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final data = jsonDecode(body);
      final sanitizedData = ValidationUtils.validateAndSanitizeProfileData(data);
      
      final profile = Profile(
        id: int.parse(id),
        userId: payload['id'],
        firstName: sanitizedData['first_name'] ?? '',
        lastName: sanitizedData['last_name'] ?? '',
        avatarUrl: sanitizedData['avatar_url'],
        bio: sanitizedData['bio'],
        sumCO2: 0, // Р—РЅР°С‡РµРЅРёРµ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
        savedMoney: 0.0, // Р—РЅР°С‡РµРЅРёРµ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
        countBuy: 0, // Р—РЅР°С‡РµРЅРёРµ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteProfile(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      await _profileService.deleteProfile(payload['id']);

      await LoggingUtils.logInfo(
        'РЈРґР°Р»РµРЅ РїСЂРѕС„РёР»СЊ',
        context: {'userId': payload['id']},
        requestId: RequestContextUtils.getRequestId(request),
      );

      final response = Response.ok(
        jsonEncode({'message': 'РџСЂРѕС„РёР»СЊ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode({'message': 'РџСЂРѕС„РёР»СЊ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'}),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json; charset=utf-8'};
  }
}
