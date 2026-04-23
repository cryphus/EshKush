import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/UserFavoriteService.dart';
import '../model/entities/UserFavorite.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';
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
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: {'content-type': 'application/json'});
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final favorites = await _service.getByUserId(payload['id'] as int);
      return Response.ok(
        jsonEncode(favorites.map((f) => f.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _isMyFavorite(Request request, String pointId) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: {'content-type': 'application/json'});
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', code: ErrorCode.badRequest, headers: {'Content-Type': 'application/json'});
      }
      final result = await _service.isFavorite(payload['id'] as int, pid);
      return Response.ok(jsonEncode({'isFavorite': result}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _addMyFavorite(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: {'content-type': 'application/json'});
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final pointId = int.tryParse(data['point_id']?.toString() ?? '') ?? 0;
      if (pointId <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', code: ErrorCode.badRequest, headers: {'Content-Type': 'application/json'});
      }
      final favorite = UserFavorite(userId: payload['id'] as int, pointId: pointId, createdAt: DateTime.now());
      final result = await _service.addToFavorites(favorite);
      return Response.ok(jsonEncode(result.toJson()), headers: {'content-type': 'application/json'});
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _removeMyFavorite(Request request, String pointId) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: {'content-type': 'application/json'});
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', code: ErrorCode.badRequest, headers: {'Content-Type': 'application/json'});
      }
      await _service.removeFromFavorites(payload['id'] as int, pid);
      return Response.ok(jsonEncode({'message': 'Место успешно удалено из избранного'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> getByPointId(Request request, String pointId) async {
    try {
      final pid = int.tryParse(pointId) ?? 0;
      if (pid <= 0) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', code: ErrorCode.badRequest, headers: {'Content-Type': 'application/json'});
      }
      final favorites = await _service.getByPointId(pid);
      return Response.ok(
        jsonEncode(favorites.map((f) => f.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'content-type': 'application/json'});
    }
  }

}

