import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointReviewService.dart';
import '../model/entities/PointReview.dart';
import '../middleware/RbacMiddleware.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class PointReviewController {
  final PointReviewService _service;
  late final Router _router;

  PointReviewController(this._service) {
    _router = Router();
    _router.get('/', _getMyReviews);
    _router.get('/point/<pointId>', _getByPointId);
    _router.get('/user/<userId>', _getByUserId);
    _router.post('/', _create);
    _router.put('/<id>', _update);
    _router.delete('/<id>', _delete);
    _router.get('/<id>', _getById);
  }

  Router get router => _router;

  Future<Response> _getMyReviews(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final userId = payload['id'] as int;
      final reviews = await _service.getByUserId(userId);
      return Response.ok(
        jsonEncode(reviews.map((r) => r.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
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
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка очистки кеша', headers: _getCorsHeaders());
      }

      final review = await _service.getById(id);
      if (review == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отзыв не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
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
      await LoggingUtils.logError('Ошибка получения отзыва по ID', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID пользователя', headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
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
          'Отзыв создан',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания отзыва', e);
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка очистки кеша', headers: _getCorsHeaders());
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отзыв не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      if (!RbacMiddleware.isOwnerOrElevated(request, existingReview.userId)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав на редактирование отзыва', code: ErrorCode.forbidden, headers: _getCorsHeaders());
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
          'Отзыв обновлён',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления отзыва', e);
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка очистки кеша', headers: _getCorsHeaders());
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отзыв не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      if (!RbacMiddleware.isOwnerOrElevated(request, existingReview.userId)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав на удаление отзыва', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      await _service.delete(id);

      await LoggingUtils.logInfo(
        'Удален отзыв',
        context: {'reviewId': id},
      );

      final responseJson = jsonEncode({'message': 'Отзыв успешно удалён'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
