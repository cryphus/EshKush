import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ChangesService.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/RequestBodyUtils.dart';

class ChangesController {
  final ChangesService _service;
  final Router _router = Router();

  ChangesController(this._service) {
    _router.get('/', _getRecentChanges);
    _router.get('/entity/<entityType>/<entityId>', _getEntityChanges);
    _router.get('/user/<userId>', _getUserChanges);
    _router.get('/type/<changeType>', _getChangeTypeChanges);
    _router.get('/recent', _getRecentChanges);
    _router.post('/<changeId>/revert', _revertChange);
  }

  Router get router => _router;

  Future<Response> _getEntityChanges(
      Request request, String entityType, String entityId) async {
    try {
      final type = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == entityType,
        orElse: () => EntityType.other,
      );
      final id = int.tryParse(entityId);
      if (id == null) {
        return Response(400,
            body: '{"error":"Некорректный ID"}',
            headers: {'content-type': 'application/json'});
      }

      final changes = await _service.getEntityChanges(type, id);
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserChanges(Request request, String userId) async {
    try {
      final id = int.tryParse(userId);
      if (id == null) {
        return Response(400,
            body: '{"error":"Некорректный ID"}',
            headers: {'content-type': 'application/json'});
      }
      final changes = await _service.getUserChanges(id);

      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getChangeTypeChanges(
      Request request, String changeType) async {
    try {
      final type = ChangeType.values.firstWhere(
        (e) => e.toString().split('.').last == changeType,
        orElse: () => ChangeType.update,
      );

      final changes = await _service.getChangeTypeChanges(type);
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getRecentChanges(Request request) async {
    try {
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final changes = await _service.getRecentChanges(limit: limit);
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _revertChange(Request request, String changeId) async {
    try {
      final id = int.tryParse(changeId);
      if (id == null) {
        return Response(400,
            body: '{"error":"Некорректный ID"}',
            headers: {'content-type': 'application/json'});
      }
      final body = await RequestBodyUtils.readRequiredBody(request);
      final data = RequestBodyUtils.decodeJsonObject(body);
      final revertedBy =
          RequestContextUtils.getUser(request)?['id'] as int? ?? 0;
      final comment = data['comment'] as String?;

      await _service.revertChange(id, revertedBy, comment: comment);
      return Response.ok(
        jsonEncode({'message': 'Изменение успешно отменено'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
