import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointService.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../model/dto/responses/PointResponseDto.dart';
import '../model/dto/requests/CreatePointDto.dart';
import '../utils/PaginationUtils.dart';

class PointController {
  final PointService _pointService;

  PointController(this._pointService);

  Router get router {
    final router = Router();

    router.get('/', _getAllPoints);
    router.get('/nearby', _getPointsNearby);
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final pagination = PaginationUtils.parse(request);
      final points = await _pointService.getAllPoints(limit: pagination.limit, offset: pagination.offset);
      final pointsJson = jsonEncode(PaginationUtils.wrap(
        points.map((p) => PointResponseDto.fromEntity(p).toJson()).toList(),
        pagination,
      ));

      final response = Response.ok(
        pointsJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointsJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка точек', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getPointById(Request request) async {
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }

      final point = await _pointService.getPointById(id);
      final pointDto = PointResponseDto.fromEntity(point);
      final pointJson = jsonEncode(pointDto.toJson());

      final response = Response.ok(
        pointJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponseWithMessage('Точка не найдена', code: ErrorCode.notFound, headers: _getCorsHeaders());
    }
  }

  Future<Response> _getPointsNearby(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final params = request.url.queryParameters;
      final lat = double.tryParse(params['lat'] ?? '');
      final lon = double.tryParse(params['lon'] ?? '');
      final radius = double.tryParse(params['radius'] ?? '') ?? 5000.0;
      final limit = int.tryParse(params['limit'] ?? '') ?? 100;

      if (lat == null || lon == null) {
        return _createErrorResponse(400, 'Параметры lat и lon обязательны');
      }
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        return _createErrorResponse(400, 'Некорректные координаты');
      }

      final nearby = await _pointService.getPointsNearby(
        lat: lat,
        lon: lon,
        radiusM: radius,
        limit: limit,
      );

      final json = jsonEncode(
        nearby
            .map((np) => PointResponseDto.fromEntity(
                  np.point,
                  distanceM: np.distanceM,
                ).toJson())
            .toList(),
      );

      final response = Response.ok(
        json,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        json,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError(
        'Ошибка геопоиска точек',
        e,
        requestId: RequestContextUtils.getRequestId(request),
      );
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> _getPointsByCategory(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final categoryId = int.tryParse(request.params['categoryId']!);
      if (categoryId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID категории', headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final points = await _pointService.getPointsByCategory(categoryId, limit: pagination.limit, offset: pagination.offset);
      final pointsJson = jsonEncode(PaginationUtils.wrap(
        points.map((p) => PointResponseDto.fromEntity(p).toJson()).toList(),
        pagination,
      ));

      final response = Response.ok(
        pointsJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        pointsJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения точек по категории', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getPointCategories(Request request) async {
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения категорий точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }
      
             try {
         final createDto = CreatePointDto.fromJson(data);
         final point = await _pointService.createPoint(createDto.toEntityData());

        await LoggingUtils.logInfo(
          'Точка создана',
          context: {
            'pointId': point.id,
            'name': point.name,
          },
          requestId: RequestContextUtils.getRequestId(request),
        );

        final pointDto = PointResponseDto.fromEntity(point);
        final pointJson = jsonEncode(pointDto.toJson());
        
        final response = Response.ok(
          pointJson,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          pointJson,
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }
      
      try {
        final createDto = CreatePointDto.fromJson(data);
        final point = await _pointService.updatePoint(id, createDto.toEntityData());
        
        final pointDto = PointResponseDto.fromEntity(point);
        final pointJson = jsonEncode(pointDto.toJson());

        await LoggingUtils.logInfo(
          'Точка обновлена',
          context: {
            'pointId': point.id,
            'name': point.name,
          },
          requestId: RequestContextUtils.getRequestId(request),
        );

        final response = Response.ok(
          pointJson,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          pointJson,
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deletePoint(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }

      await _pointService.deletePoint(id);

      await LoggingUtils.logInfo(
        'Точка успешно удалена',
        context: {'pointId': id},
        requestId: RequestContextUtils.getRequestId(request),
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }
      if (data['rating'] == null || !ValidationUtils.isValidNumber(data['rating'], min: 0, max: 5)) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный формат данных', headers: _getCorsHeaders());
      }

      await _pointService.updateRating(id, (data['rating'] as num).toDouble());

      await LoggingUtils.logInfo(
        'Обновлён рейтинг точки',
        context: {
          'pointId': id,
          'rating': data['rating'],
        },
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseJson = jsonEncode({'message': 'Рейтинг точки обновлён'});
      final response = Response.ok(
        responseJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления рейтинга', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }
      if (data['categoryIds'] == null || !(data['categoryIds'] is List)) {
        return ErrorResponseUtils.errorResponseWithMessage('Необходимо передать список categoryIds', code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }

      final categoryIds = (data['categoryIds'] as List).map((id) => id as int).toList();
      await _pointService.updatePointCategories(id, categoryIds);

      await LoggingUtils.logInfo(
        'РћР±РЅРѕРІР»РµРЅС‹ РєР°С‚РµРіРѕСЂРёРё С‚РѕС‡РєРё',
        context: {
          'pointId': id,
          'categoryIds': categoryIds,
        },
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseJson = jsonEncode({'message': 'РљР°С‚РµРіРѕСЂРёРё СѓСЃРїРµС€РЅРѕ РѕР±РЅРѕРІР»РµРЅС‹'});
      final response = Response.ok(
        responseJson,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseJson,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления категорий точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getPointReviews(Request request) async {
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения отзывов точки', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final payload = RequestContextUtils.getUser(request)!;
      final userId = payload['id'] as int;
      
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }

      final data = jsonDecode(body);
      data['point_id'] = id;
      data['user_id'] = userId;
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewData(data);
        final review = await _pointService.createPointReview(sanitizedData);
        final reviewJson = jsonEncode(review.toJson());

        await LoggingUtils.logInfo(
          'Некорректная сумма',
          context: {
            'reviewId': review.id,
            'pointId': review.pointId,
            'userId': review.userId,
          },
          requestId: RequestContextUtils.getRequestId(request),
        );

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
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания отзыва', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }


  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
