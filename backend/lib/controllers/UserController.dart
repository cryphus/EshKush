import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/UserService.dart';
import '../utils/AuthUtils.dart';
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
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final user = await _userService.getUserById(payload['id']);

      final userDto = UserResponseDto.fromEntity(user);
      final body = jsonEncode(userDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateProfile(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final payload = AuthUtils.verifyToken(token);

      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, SafeLoggingUtils.sanitizeString(body), requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      SafeLoggingUtils.logData('Р”Р°РЅРЅС‹Рµ РґР»СЏ РѕР±РЅРѕРІР»РµРЅРёСЏ', data);
      
      try {
        final updateDto = UpdateUserDto.fromJson(data);
        
        if (!updateDto.hasFields) {
          return Response(400, 
            body: jsonEncode({'error': 'РќРµС‚ РїРѕР»РµР№ РґР»СЏ РѕР±РЅРѕРІР»РµРЅРёСЏ'}),
            headers: _getCorsHeaders(),
          );
        }

        if (data['id'] != null && data['id'] != payload['id']) {
          return Response(403, 
            body: jsonEncode({'error': 'РќРµС‚ РїСЂР°РІ РЅР° РёР·РјРµРЅРµРЅРёРµ СЌС‚РѕРіРѕ РїСЂРѕС„РёР»СЏ'}),
            headers: _getCorsHeaders(),
          );
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
         return Response(400, 
           body: jsonEncode({'error': e.message}),
           headers: _getCorsHeaders(),
         );
       }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.addToFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'РўРѕС‡РєР° РґРѕР±Р°РІР»РµРЅР° РІ РёР·Р±СЂР°РЅРЅРѕРµ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
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
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['point_id'] == null || data['point_id'] <= 0) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.removeFromFavorites(payload['id'], data['point_id']);
      final body = jsonEncode({'message': 'РўРѕС‡РєР° СѓРґР°Р»РµРЅР° РёР· РёР·Р±СЂР°РЅРЅРѕРіРѕ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
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
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['amount'] == null || data['amount'].abs() > 1000000) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅР°СЏ СЃСѓРјРјР°'}),
          headers: _getCorsHeaders(),
        );
      }

      await _userService.updateBalance(payload['id'], data['amount']);
      final body = jsonEncode({'message': 'Р‘Р°Р»Р°РЅСЃ РѕР±РЅРѕРІР»РµРЅ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
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
