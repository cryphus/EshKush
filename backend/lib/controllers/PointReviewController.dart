import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointReviewService.dart';
import '../model/entities/PointReview.dart';
import '../utils/AuthUtils.dart';
import '../middleware/RbacMiddleware.dart';
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РѕС‚Р·С‹РІР°');
      }

      final review = await _service.getById(id);
      if (review == null) {
        return _createErrorResponse(404, 'РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕС‚Р·С‹РІР°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕС‚Р·С‹РІРѕРІ С‚РѕС‡РєРё', e);
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕС‚Р·С‹РІРѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ', e);
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = payload['id'] as int;
      data['user_id'] = userId;

      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewData(data);
        final review = PointReview(
          id: 0, // Р’СЂРµРјРµРЅРЅС‹Р№ ID, Р±СѓРґРµС‚ Р·Р°РјРµРЅРµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё РІ Р‘Р”
          pointId: sanitizedData['point_id'] as int,
          userId: sanitizedData['user_id'] as int,
          rating: sanitizedData['rating'] as double,
          comment: sanitizedData['comment'] as String?,
          createdAt: DateTime.now(),
        );
        final created = await _service.create(review);

        await LoggingUtils.logInfo(
          'РЎРѕР·РґР°РЅ РЅРѕРІС‹Р№ РѕС‚Р·С‹РІ',
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
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РѕС‚Р·С‹РІР°', e);
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РѕС‚Р·С‹РІР°');
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return _createErrorResponse(404, 'РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
      }

      if (!RbacMiddleware.isOwnerOrElevated(request, existingReview.userId)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РЅР° СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ РѕС‚Р·С‹РІР°');
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
          'РћР±РЅРѕРІР»РµРЅ РѕС‚Р·С‹РІ',
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РѕС‚Р·С‹РІР°', e);
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РѕС‚Р·С‹РІР°');
      }

      final existingReview = await _service.getById(id);
      if (existingReview == null) {
        return _createErrorResponse(404, 'РћС‚Р·С‹РІ РЅРµ РЅР°Р№РґРµРЅ');
      }

      if (!RbacMiddleware.isOwnerOrElevated(request, existingReview.userId)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РЅР° СѓРґР°Р»РµРЅРёРµ РѕС‚Р·С‹РІР°');
      }

      await _service.delete(id);

      await LoggingUtils.logInfo(
        'РЈРґР°Р»РµРЅ РѕС‚Р·С‹РІ',
        context: {'reviewId': id},
      );

      final responseJson = jsonEncode({'message': 'РћС‚Р·С‹РІ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'});
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
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РѕС‚Р·С‹РІР°', e);
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
    return {'Content-Type': 'application/json'};
  }
}
