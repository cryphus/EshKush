import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/UserService.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/UserResponseDto.dart';
import '../model/dto/requests/UpdateUserDto.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';

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
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final user = await _userService.getUserById(payload['id']);

      final userDto = UserResponseDto.fromEntity(user);
      final body = jsonEncode(userDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));

      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, SafeLoggingUtils.sanitizeString(body), requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      SafeLoggingUtils.logData('Ошибка очистки кеша', data);
      
      try {
        final updateDto = UpdateUserDto.fromJson(data);
        
        if (!updateDto.hasFields) {
          return ErrorResponseUtils.errorResponseWithMessage('Нет полей для обновления', headers: _getCorsHeaders());
        }

        if (data['id'] != null && data['id'] != payload['id']) {
          return ErrorResponseUtils.errorResponseWithMessage('Нет прав на изменение этого профиля', code: ErrorCode.forbidden, headers: _getCorsHeaders());
        }

        // РљРѕРЅРІРµСЂС‚РёСЂСѓРµРј DTO РІ РґР°РЅРЅС‹Рµ РґР»СЏ СЃРµСЂРІРёСЃР°
        final updateData = updateDto.toEntityData();
        final user = await _userService.updateUser(payload['id'], updateData);
        
        final userDto = UserResponseDto.fromEntity(user);
         final bodyOut = jsonEncode(userDto.toJson());
         final resp = Response.ok(bodyOut, headers: _getCorsHeaders());
         await LoggingUtils.logResponse(resp.statusCode, resp.headers, bodyOut, requestId: RequestContextUtils.getRequestId(request));
         return resp;
       } on ValidationException catch (e) {
         return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
       }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final data = jsonDecode(await request.readAsString());
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный идентификатор точки', headers: _getCorsHeaders());
      }
      await _userService.addToFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'Точка добавлена в избранное'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final data = jsonDecode(await request.readAsString());
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный идентификатор точки', headers: _getCorsHeaders());
      }
      await _userService.removeFromFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'Точка удалена из избранного'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> updateBalance(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final data = jsonDecode(await request.readAsString());
      if (data['amount'] == null || data['amount'].abs() > 1000000) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректная сумма', headers: _getCorsHeaders());
      }

      await _userService.updateBalance(payload['id'], data['amount']);
      final body = jsonEncode({'message': 'Некорректный ID'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
