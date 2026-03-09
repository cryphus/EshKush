import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ErrorLogsService.dart';
import '../utils/ErrorResponseUtils.dart';
import '../model/enums/ErrorSeverity.dart';
import '../utils/AuthUtils.dart';

class ErrorLogsController {
  final ErrorLogsService _service;

  ErrorLogsController(this._service);

  Router get router {
    final router = Router();
    router.get('/severity', getErrorsBySeverity);
    router.get('/module', getErrorsByModule);
    router.get('/user', getUserErrors);
    router.get('/unresolved', getUnresolvedErrors);
    router.get('/recent', getRecentErrors);
    router.post('/resolve', markErrorAsResolved);
    router.post('/log', logError);
    return router;
  }

  Future<Response> getErrorsBySeverity(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final severity = ErrorSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['severity'],
        orElse: () => ErrorSeverity.medium,
      );
      
      final errors = await _service.getErrorsBySeverity(severity);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getErrorsByModule(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final module = request.url.queryParameters['module'] ?? '';
      final errors = await _service.getErrorsByModule(module);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUserErrors(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final errors = await _service.getUserErrors(userId);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getUnresolvedErrors(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final errors = await _service.getUnresolvedErrors();
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getRecentErrors(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final errors = await _service.getRecentErrors(limit: limit);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> markErrorAsResolved(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final errorId = int.tryParse(request.url.queryParameters['errorId'] ?? '');
      final resolvedBy = request.url.queryParameters['resolvedBy'] ?? '';
      
      if (errorId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РѕС€РёР±РєРё'}),
          headers: _getCorsHeaders(),
        );
      }
      
      await _service.markErrorAsResolved(errorId, resolvedBy);
      return Response.ok(
        jsonEncode({'message': 'РћС€РёР±РєР° СѓСЃРїРµС€РЅРѕ РѕС‚РјРµС‡РµРЅР° РєР°Рє СЂРµС€РµРЅРЅР°СЏ'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> logError(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['errorMessage'] == null || data['errorCode'] == null || 
          data['stackTrace'] == null || data['severity'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓСЋС‚ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final severity = ErrorSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
        orElse: () => ErrorSeverity.medium,
      );

      final error = await _service.logError(
        errorMessage: data['errorMessage'],
        errorCode: data['errorCode'],
        stackTrace: data['stackTrace'],
        severity: severity,
        module: data['module'],
        userId: data['userId'],
        additionalInfo: data['additionalInfo'],
      );

      return Response.ok(
        jsonEncode(error.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
