import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointService.dart';
import '../model/entities/Point.dart';
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
    router.get('/points/category/<categoryId>', _getPointsByCategory);
    router.get('/points/<id>/categories', _getPointCategories);
    router.post('/points', _createPoint);
    router.put('/points/<id>', _updatePoint);
    router.put('/points/<id>/categories', _updatePointCategories);
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

      final points = await _pointService.getAllPoints();

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

  Future<Response> _getPointsByCategory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final categoryId = int.tryParse(request.params['categoryId']!);
      if (categoryId == null) {
        return _createErrorResponse(400, 'Некорректный ID категории');
      }

      final points = await _pointService.getPointsByCategory(categoryId);

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
      await LoggingUtils.logError('Ошибка получения точек по категории', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _getPointCategories(Request request) async {
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

      final categories = await _pointService.getPointCategories(id);

      final response = Response.ok(
        jsonEncode(categories.map((c) => c.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения категорий точки', e);
      return _createErrorResponse(500, 'Ошибка: $e');
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

  Future<Response> _updatePointCategories(Request request) async {
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
      if (data['categoryIds'] == null || !(data['categoryIds'] is List)) {
        return _createErrorResponse(400, 'Некорректный формат данных');
      }

      final categoryIds = (data['categoryIds'] as List).map((id) => id as int).toList();
      await _pointService.updatePointCategories(id, categoryIds);

      await LoggingUtils.logInfo(
        'Обновлены категории точки',
        context: {
          'pointId': id,
          'categoryIds': categoryIds,
        },
      );

      final response = Response.ok(
        jsonEncode({'message': 'Категории успешно обновлены'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления категорий точки', e);
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