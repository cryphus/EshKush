import 'package:shelf/shelf.dart';
import '../services/ChangesService.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';

class ChangesController {
  final ChangesService _service;

  ChangesController(this._service);

  Future<Response> getEntityChanges(Request request) async {
    try {
      final entityType = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['entityType'],
        orElse: () => EntityType.other,
      );
      final entityId = int.parse(request.url.queryParameters['entityId'] ?? '');
      
      final changes = await _service.getEntityChanges(entityType, entityId);
      return Response.ok(
        changes.map((change) => change.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения изменений сущности: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getUserChanges(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId'] ?? '');
      final changes = await _service.getUserChanges(userId);
      return Response.ok(
        changes.map((change) => change.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения изменений пользователя: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getChangeTypeChanges(Request request) async {
    try {
      final changeType = ChangeType.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['changeType'],
        orElse: () => ChangeType.update,
      );
      
      final changes = await _service.getChangeTypeChanges(changeType);
      return Response.ok(
        changes.map((change) => change.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения изменений по типу: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getRecentChanges(Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final changes = await _service.getRecentChanges(limit: limit);
      return Response.ok(
        changes.map((change) => change.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения последних изменений: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> revertChange(Request request) async {
    try {
      final changeId = int.parse(request.url.queryParameters['changeId'] ?? '');
      final revertedBy = int.parse(request.url.queryParameters['revertedBy'] ?? '');
      final comment = request.url.queryParameters['comment'];
      
      await _service.revertChange(changeId, revertedBy, comment: comment);
      return Response.ok(
        {'message': 'Изменение успешно отменено'},
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка отмены изменения: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 