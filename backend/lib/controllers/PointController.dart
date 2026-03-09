import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/PointResponseDto.dart';
import '../model/dto/requests/CreatePointDto.dart';

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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final points = await _pointService.getAllPoints();
      final pointsJson = jsonEncode(points.map((p) => PointResponseDto.fromEntity(p).toJson()).toList());

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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРёСЃРєР° С‚РѕС‡РµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(404, 'РўРѕС‡РєР° РЅРµ РЅР°Р№РґРµРЅР°');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РєР°С‚РµРіРѕСЂРёРё');
      }

      final points = await _pointService.getPointsByCategory(categoryId);
      final pointsJson = jsonEncode(points.map((p) => PointResponseDto.fromEntity(p).toJson()).toList());

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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚РѕС‡РµРє РїРѕ РєР°С‚РµРіРѕСЂРёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёР№ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }
      
             try {
         final createDto = CreatePointDto.fromJson(data);
         final point = await _pointService.createPoint(createDto.toEntityData());

        await LoggingUtils.logInfo(
          'РЎРѕР·РґР°РЅР° РЅРѕРІР°СЏ С‚РѕС‡РєР°',
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
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }
      
      try {
        final createDto = CreatePointDto.fromJson(data);
        final point = await _pointService.updatePoint(id, createDto.toEntityData());
        
        final pointDto = PointResponseDto.fromEntity(point);
        final pointJson = jsonEncode(pointDto.toJson());

        await LoggingUtils.logInfo(
          'РћР±РЅРѕРІР»РµРЅР° С‚РѕС‡РєР°',
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
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }

      await _pointService.deletePoint(id);

      await LoggingUtils.logInfo(
        'РЈРґР°Р»РµРЅР° С‚РѕС‡РєР°',
        context: {'pointId': id},
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseJson = jsonEncode({'message': 'РўРѕС‡РєР° СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅР°'});
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
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }

      if (data['rating'] == null || !ValidationUtils.isValidNumber(data['rating'], min: 0, max: 5)) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ СЂРµР№С‚РёРЅРі');
      }

      await _pointService.updateRating(id, (data['rating'] as num).toDouble());

      await LoggingUtils.logInfo(
        'РћР±РЅРѕРІР»РµРЅ СЂРµР№С‚РёРЅРі С‚РѕС‡РєРё',
        context: {
          'pointId': id,
          'rating': data['rating'],
        },
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseJson = jsonEncode({'message': 'Р РµР№С‚РёРЅРі СѓСЃРїРµС€РЅРѕ РѕР±РЅРѕРІР»РµРЅ'});
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЂРµР№С‚РёРЅРіР°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);

      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }

      if (data['categoryIds'] == null || !(data['categoryIds'] is List)) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ РґР°РЅРЅС‹С…');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёР№ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕС‚Р·С‹РІРѕРІ С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = payload['id'] as int;
      
      final id = int.tryParse(request.params['id']!);
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }

      final data = jsonDecode(body);
      data['point_id'] = id;
      data['user_id'] = userId;
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeReviewData(data);
        final review = await _pointService.createPointReview(sanitizedData);
        final reviewJson = jsonEncode(review.toJson());

        await LoggingUtils.logInfo(
          'РЎРѕР·РґР°РЅ РЅРѕРІС‹Р№ РѕС‚Р·С‹РІ',
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
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РѕС‚Р·С‹РІР°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
    return {'Content-Type': 'application/json'};
  }
} 
