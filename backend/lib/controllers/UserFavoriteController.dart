import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/UserFavoriteService.dart';
import '../model/entities/UserFavorite.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import 'dart:convert';

class UserFavoriteController {
  final UserFavoriteService _service;
  final Router _router = Router();

  UserFavoriteController(this._service);

  Router get router => _router
    ..get('/', _getMyFavorites)
    ..post('/', _addMyFavorite)
    ..delete('/<pointId|[^/]+>', _removeMyFavorite)
    ..get('/point/<pointId|[^/]+>', getByPointId)
    ..get('/is-favorite/<pointId|[^/]+>', _isMyFavorite);

  Future<Response> _getMyFavorites(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}), headers: {'content-type': 'application/json'});
      }
      final payload = AuthUtils.verifyToken(token);
      final favorites = await _service.getByUserId(payload['id'] as int);
      return Response.ok(
        jsonEncode(favorites.map((f) => f.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _isMyFavorite(Request request, String pointId) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}), headers: {'content-type': 'application/json'});
      }
      final payload = AuthUtils.verifyToken(token);
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return Response(400, body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}), headers: {'content-type': 'application/json'});
      }
      final result = await _service.isFavorite(payload['id'] as int, pid);
      return Response.ok(jsonEncode({'isFavorite': result}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _addMyFavorite(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}), headers: {'content-type': 'application/json'});
      }
      final payload = AuthUtils.verifyToken(token);
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final pointId = int.tryParse(data['point_id']?.toString() ?? '') ?? 0;
      if (pointId <= 0) {
        return Response(400, body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}), headers: {'content-type': 'application/json'});
      }
      final favorite = UserFavorite(userId: payload['id'] as int, pointId: pointId, createdAt: DateTime.now());
      final result = await _service.addToFavorites(favorite);
      return Response.ok(jsonEncode(result.toJson()), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _removeMyFavorite(Request request, String pointId) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}), headers: {'content-type': 'application/json'});
      }
      final payload = AuthUtils.verifyToken(token);
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return Response(400, body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}), headers: {'content-type': 'application/json'});
      }
      await _service.removeFromFavorites(payload['id'] as int, pid);
      return Response.ok(jsonEncode({'message': 'РњРµСЃС‚Рѕ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅРѕ РёР· РёР·Р±СЂР°РЅРЅРѕРіРѕ'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getByUserId(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final favorites = await _service.getByUserId(userId);
      return Response.ok(
        favorites.map((f) => f.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getByPointId(Request request, String pointId) async {
    try {
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return Response(400,
            body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ С‚РѕС‡РєРё'}),
            headers: {'content-type': 'application/json'});
      }
      final favorites = await _service.getByPointId(pid);
      return Response.ok(
        jsonEncode(favorites.map((f) => f.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final favorite = UserFavorite.fromJson(json);
      final result = await _service.addToFavorites(favorite);
      return Response.ok(
        result.toJson().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      await _service.removeFromFavorites(userId, pointId);
      return Response.ok(
        {'message': 'РњРµСЃС‚Рѕ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅРѕ РёР· РёР·Р±СЂР°РЅРЅРѕРіРѕ'}.toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> isFavorite(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      final result = await _service.isFavorite(userId, pointId);
      return Response.ok(
        {'isFavorite': result}.toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 
