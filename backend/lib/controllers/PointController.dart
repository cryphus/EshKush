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

    router.get('/', _getAllPoints);
    router.get('/<id>', _getPointById);
    router.get('/category/<categoryId>', _getPointsByCategory);
    router.get('/<id>/categories', _getPointCategories);
    router.post('/', _createPoint);
    router.put('/<id>', _updatePoint);
    router.put('/<id>/categories', _updatePointCategories);
    router.delete('/<id>', _deletePoint);
    router.put('/<id>/rating', _updateRating);
    router.get('/<id>/reviews', _getPointReviews);
    router.post('/<id>/reviews', _createPointReview);

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
      final pointsJson = jsonEncode(points.map((p) => p.toJson()).toList());

      final response = Response.ok(
        pointsJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointsJson,
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
      final pointJson = jsonEncode(point.toJson());

      final response = Response.ok(
        pointJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointJson,
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
      final pointsJson = jsonEncode(points.map((p) => p.toJson()).toList());

      final response = Response.ok(
        pointsJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointsJson,
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
      final categoriesJson = jsonEncode(categories.map((c) => c.toJson()).toList());

      final response = Response.ok(
        categoriesJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        categoriesJson,
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
      final data = jsonDecode(body);
      
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
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizePointDataForCreate(data);
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
          jsonEncode(point.toJson()),
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
      final data = jsonDecode(body);
      
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
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizePointDataForUpdate(data);
        final point = await _pointService.updatePoint(id, sanitizedData);
        final pointJson = jsonEncode(point.toJson());

        await LoggingUtils.logInfo(
          'Обновлена точка',
          context: {
            'pointId': point.id,
            'name': point.name,
          },
        );

        final response = Response.ok(
          pointJson,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          pointJson,
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

      final responseJson = jsonEncode({'message': 'Точка успешно удалена'});
      final response = Response.ok(
        responseJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseJson,
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
      final data = jsonDecode(body);
      
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

      final responseJson = jsonEncode({'message': 'Рейтинг успешно обновлен'});
      final response = Response.ok(
        responseJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseJson,
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
      final data = jsonDecode(body);
      
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

      final responseJson = jsonEncode({'message': 'Категории успешно обновлены'});
      final response = Response.ok(
        responseJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseJson,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления категорий точки', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> _getPointReviews(Request request) async {
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

      final reviews = await _pointService.getPointReviews(id);
      final reviewsJson = jsonEncode(reviews.map((r) => r.toJson()).toList());

      final response = Response.ok(
        reviewsJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        reviewsJson,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения отзывов точки', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _createPointReview(Request request) async {
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
      final userId = payload['id'] as int;
      
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final data = jsonDecode(body);
      data['point_id'] = id;
      data['user_id'] = userId;
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewData(data);
        final review = await _pointService.createPointReview(sanitizedData);
        final reviewJson = jsonEncode(review.toJson());

        await LoggingUtils.logInfo(
          'Создан новый отзыв',
          context: {
            'reviewId': review.id,
            'pointId': review.pointId,
            'userId': review.userId,
          },
        );

        final response = Response.ok(
          reviewJson,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          reviewJson,
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания отзыва', e);
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