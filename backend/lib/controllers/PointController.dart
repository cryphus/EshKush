import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointService.dart';
import '../model/entities/Point.dart';
import '../model/enums/PointCategory.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

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
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final category = request.url.queryParameters['category'];
      final points = await _pointService.getAllPoints(
        category: category != null ? PointCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == category.toLowerCase(),
          orElse: () => PointCategory.other,
        ) : null,
      );

      final response = Response.ok(
        jsonEncode(points.map((p) => p.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка точек', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _getPointById(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final point = await _pointService.getPointById(id);

      final response = Response.ok(
        jsonEncode(point.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения точки', e);
      return _createErrorResponse(404, 'Точка не найдена');
    }
  }

  Future<Response> _createPoint(Request request) async {
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
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizePointData(data);
        final point = await _pointService.createPoint(sanitizedData);

        await LoggingUtils.logInfo(
          'Создана новая точка',
          context: {
            'pointId': point.id,
            'name': point.name,
            'category': point.category.toString(),
          },
        );

        final response = Response.ok(
          jsonEncode(point.toJson()),
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
      await LoggingUtils.logError('Ошибка создания точки', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> _updatePoint(Request request) async {
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
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizePointData(data);
        final point = await _pointService.updatePoint(id, sanitizedData);

        await LoggingUtils.logInfo(
          'Обновлена точка',
          context: {
            'pointId': point.id,
            'name': point.name,
            'category': point.category.toString(),
          },
        );

        final response = Response.ok(
          jsonEncode(point.toJson()),
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
      await LoggingUtils.logError('Ошибка обновления точки', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> _deletePoint(Request request) async {
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
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      await _pointService.deletePoint(id);

      await LoggingUtils.logInfo(
        'Удалена точка',
        context: {'pointId': id},
      );

      final response = Response.ok(
        jsonEncode({'message': 'Точка успешно удалена'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления точки', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> _updateRating(Request request) async {
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
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final data = jsonDecode(body);
      if (data['rating'] == null || !ValidationUtils.isValidNumber(data['rating'], min: 0, max: 5)) {
        return _createErrorResponse(400, 'Некорректный рейтинг');
      }

      await _pointService.updateRating(id, (data['rating'] as num).toDouble());

      await LoggingUtils.logInfo(
        'Обновлен рейтинг точки',
        context: {
          'pointId': id,
          'rating': data['rating'],
        },
      );

      final response = Response.ok(
        jsonEncode({'message': 'Рейтинг успешно обновлен'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления рейтинга', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
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