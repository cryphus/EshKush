import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointReviewService.dart';
import '../model/entities/PointReview.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class PointReviewController {
  final PointReviewService _service;

  PointReviewController(this._service);

  Router get router {
    final router = Router();

    router.get('/<id>', _getById);
    router.get('/point/<pointId>', _getByPointId);
    router.get('/user/<userId>', _getByUserId);
    router.post('/', _create);
    router.put('/<id>', _update);
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _getById(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID отзыва');
      }

      final review = await _service.getById(id);
      if (review == null) {
        return _createErrorResponse(404, 'Отзыв не найден');
      }

      final reviewJson = jsonEncode(review.toJson());
      final response = Response.ok(
        reviewJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        reviewJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения отзыва', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _getByPointId(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final pointId = int.tryParse(request.params['pointId']!);
      if (pointId == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final reviews = await _service.getByPointId(pointId);
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

  Future<Response> _getByUserId(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final userId = int.tryParse(request.params['userId']!);
      if (userId == null) {
        return _createErrorResponse(400, 'Некорректный ID пользователя');
      }

      final reviews = await _service.getByUserId(userId);
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
      await LoggingUtils.logError('Ошибка получения отзывов пользователя', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _create(Request request) async {
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
      final userId = payload['id'] as int;
      data['user_id'] = userId;

      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewData(data);
        final review = PointReview(
          id: 0, // Временный ID, будет заменен при создании в БД
          pointId: sanitizedData['point_id'] as int,
          userId: sanitizedData['user_id'] as int,
          rating: sanitizedData['rating'] as double,
          comment: sanitizedData['comment'] as String?,
          createdAt: DateTime.now(),
        );
        final created = await _service.create(review);

        await LoggingUtils.logInfo(
          'Создан новый отзыв',
          context: {
            'reviewId': created.id,
            'pointId': created.pointId,
            'userId': created.userId,
          },
        );

        final response = Response.ok(
          jsonEncode(created.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          jsonEncode(created.toJson()),
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

  Future<Response> _update(Request request) async {
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
        return _createErrorResponse(400, 'Некорректный ID отзыва');
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return _createErrorResponse(404, 'Отзыв не найден');
      }

      if (existingReview.userId != payload['id'] && payload['role'] != 'admin') {
        return _createErrorResponse(403, 'Нет прав на редактирование отзыва');
      }

      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewDataForUpdate(data);
        final review = PointReview(
          id: id,
          pointId: existingReview.pointId,
          userId: existingReview.userId,
          rating: sanitizedData['rating'] ?? existingReview.rating,
          comment: sanitizedData['comment'] ?? existingReview.comment,
          createdAt: existingReview.createdAt,
        );
        final updated = await _service.update(review);

        await LoggingUtils.logInfo(
          'Обновлен отзыв',
          context: {
            'reviewId': updated.id,
            'pointId': updated.pointId,
            'userId': updated.userId,
          },
        );

        final response = Response.ok(
          jsonEncode(updated.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          jsonEncode(updated.toJson()),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления отзыва', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> _delete(Request request) async {
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
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'Некорректный ID отзыва');
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return _createErrorResponse(404, 'Отзыв не найден');
      }

      if (existingReview.userId != payload['id'] && payload['role'] != 'admin') {
        return _createErrorResponse(403, 'Нет прав на удаление отзыва');
      }

      await _service.delete(id);

      await LoggingUtils.logInfo(
        'Удален отзыв',
        context: {'reviewId': id},
      );

      final responseJson = jsonEncode({'message': 'Отзыв успешно удален'});
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
      await LoggingUtils.logError('Ошибка удаления отзыва', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
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