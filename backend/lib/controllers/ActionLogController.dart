import 'package:shelf/shelf.dart';
import '../services/ActionLogService.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';

class ActionLogController {
  final ActionLogService _service;

  ActionLogController(this._service);

  Future<Response> getUserLogs(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId'] ?? '');
      final logs = await _service.getUserLogs(userId);
      return Response.ok(
        logs.map((log) => log.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов пользователя: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getEntityLogs(Request request) async {
    try {
      final entityType = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['entityType'],
        orElse: () => EntityType.other,
      );
      final entityId = int.parse(request.url.queryParameters['entityId'] ?? '');
      
      final logs = await _service.getEntityLogs(entityType, entityId);
      return Response.ok(
        logs.map((log) => log.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов сущности: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getActionTypeLogs(Request request) async {
    try {
      final actionType = ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['actionType'],
        orElse: () => ActionType.other,
      );
      
      final logs = await _service.getActionTypeLogs(actionType);
      return Response.ok(
        logs.map((log) => log.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов по типу действия: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getRecentLogs(Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final logs = await _service.getRecentLogs(limit: limit);
      return Response.ok(
        logs.map((log) => log.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения последних логов: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 