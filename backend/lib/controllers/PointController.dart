import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/PointService.dart';
import '../model/entities/Point.dart';
import '../model/enums/PointCategory.dart';
import '../utils/AuthUtils.dart';

class PointController {
  final PointService _pointService;

  PointController(this._pointService);

  Router get router {
    final router = Router();

    router.get('/points', _getAllPoints);
    router.get('/points/<id>', _getPointById);
    router.post('/points', _createPoint);
    router.put('/points/<id>', _updatePoint);
    router.delete('/points/<id>', _deletePoint);
    router.put('/points/<id>/rating', _updateRating);

    return router;
  }

  Future<Response> _getAllPoints(Request request) async {
    try {
      final category = request.url.queryParameters['category'];
      final points = await _pointService.getAllPoints(
        category: category != null ? PointCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == category.toLowerCase(),
          orElse: () => PointCategory.other,
        ) : null,
      );

      return Response.ok(
        points.map((p) => p.toJson()).toList().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getPointById(Request request) async {
    try {
      final id = int.parse(request.params['id']!);
      final point = await _pointService.getPointById(id);

      return Response.ok(
        point.toJson().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.notFound(
        {'error': 'Точка не найдена'}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createPoint(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      final point = await _pointService.createPoint(data as Map<String, dynamic>);

      return Response.ok(
        point.toJson().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _updatePoint(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      final data = await request.readAsString();
      final point = await _pointService.updatePoint(id, data as Map<String, dynamic>);

      return Response.ok(
        point.toJson().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deletePoint(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      await _pointService.deletePoint(id);

      return Response.ok(
        {'message': 'Точка успешно удалена'}.toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _updateRating(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      final data = await request.readAsString();
      final rating = (data as Map<String, dynamic>)['rating'] as double;
      
      await _pointService.updateRating(id, rating);

      return Response.ok(
        {'message': 'Рейтинг успешно обновлен'}.toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<bool> _isAuthorized(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null) return false;

    try {
      final token = authHeader.split(' ').last;
      final payload = await AuthUtils.verifyToken(token);
      return payload != null;
    } catch (e) {
      return false;
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
      'Content-Type': 'application/json',
    };
  }
} 