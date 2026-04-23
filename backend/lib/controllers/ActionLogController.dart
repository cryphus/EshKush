import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ActionLogService.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class ActionLogController {
  final ActionLogService _service;

  late final Router _router;

  ActionLogController(this._service) {
    _router = Router();
    _router.get('/', getRecentLogs);
    _router.get('/user', getUserLogs);
    _router.get('/entity', getEntityLogs);
    _router.get('/action-type', getActionTypeLogs);
    _router.get('/recent', getRecentLogs);
    _router.post('/log', logAction);
  }

  Router get router => _router;

  Future<Response> getUserLogs(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');
      
      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID пользователя', headers: _getCorsHeaders());
      }

      final logs = await _service.getUserLogs(userId);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getEntityLogs(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final entityType = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['entityType'],
        orElse: () => EntityType.other,
      );
      final entityId = int.tryParse(request.url.queryParameters['entityId'] ?? '');
      
      if (entityId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID сущности', headers: _getCorsHeaders());
      }
      
      final logs = await _service.getEntityLogs(entityType, entityId);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getActionTypeLogs(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final actionType = ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['actionType'],
        orElse: () => ActionType.other,
      );
      
      final logs = await _service.getActionTypeLogs(actionType);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getRecentLogs(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final logs = await _service.getRecentLogs(limit: limit);
      return Response.ok(
        jsonEncode(logs.map((log) => log.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> logAction(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = jsonDecode(await request.readAsString());
      
      if (data['userId'] == null || data['actionType'] == null || 
          data['targetEntity'] == null || data['targetId'] == null ||
          data['details'] == null || data['ipAddress'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Отсутствуют обязательные поля', headers: _getCorsHeaders());
      }

      final actionType = ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['actionType'],
        orElse: () => ActionType.other,
      );
      
      final targetEntity = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['targetEntity'],
        orElse: () => EntityType.other,
      );

      final log = await _service.logAction(
        userId: data['userId'],
        actionType: actionType,
        targetEntity: targetEntity,
        targetId: data['targetId'],
        details: data['details'],
        ipAddress: data['ipAddress'],
        userAgent: data['userAgent'],
        location: data['location'],
        metadata: data['metadata'],
      );

      return Response.ok(
        jsonEncode(log.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
