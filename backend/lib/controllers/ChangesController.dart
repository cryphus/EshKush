import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ChangesService.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';

class ChangesController {
  final ChangesService _service;
  final Router _router = Router();

  ChangesController(this._service) {
    _router.get('/entity/<entityType>/<entityId>', _getEntityChanges);
    _router.get('/user/<userId>', _getUserChanges);
    _router.get('/type/<changeType>', _getChangeTypeChanges);
    _router.get('/recent', _getRecentChanges);
    _router.post('/<changeId>/revert', _revertChange);
  }

  Router get router => _router;

  Future<Response> _getEntityChanges(Request request, String entityType, String entityId) async {
    try {
      final type = EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == entityType,
        orElse: () => EntityType.other,
      );
      final id = int.parse(entityId);
      
      final changes = await _service.getEntityChanges(type, id);
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёР·РјРµРЅРµРЅРёР№ СЃСѓС‰РЅРѕСЃС‚Рё: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserChanges(Request request, String userId) async {
    try {
      print('РџРѕР»СѓС‡РµРЅ Р·Р°РїСЂРѕСЃ РЅР° РїРѕР»СѓС‡РµРЅРёРµ РёР·РјРµРЅРµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ:');
      print('User ID: $userId');
      print('Headers: ${request.headers}');
      print('Method: ${request.method}');
      print('URL: ${request.url}');
      
      final id = int.parse(userId);
      final changes = await _service.getUserChanges(id);
      
      print('РќР°Р№РґРµРЅРѕ РёР·РјРµРЅРµРЅРёР№: ${changes.length}');
      
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёР·РјРµРЅРµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёР·РјРµРЅРµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getChangeTypeChanges(Request request, String changeType) async {
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
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёР·РјРµРЅРµРЅРёР№ РїРѕ С‚РёРїСѓ: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getRecentChanges(Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final changes = await _service.getRecentChanges(limit: limit);
      return Response.ok(
        jsonEncode(changes.map((change) => change.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕСЃР»РµРґРЅРёС… РёР·РјРµРЅРµРЅРёР№: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _revertChange(Request request, String changeId) async {
    try {
      final id = int.parse(changeId);
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final revertedBy = int.parse(request.headers['user-id'] ?? '0');
      final comment = data['comment'] as String?;
      
      await _service.revertChange(id, revertedBy, comment: comment);
      return Response.ok(
        jsonEncode({'message': 'РР·РјРµРЅРµРЅРёРµ СѓСЃРїРµС€РЅРѕ РѕС‚РјРµРЅРµРЅРѕ'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РѕС‚РјРµРЅС‹ РёР·РјРµРЅРµРЅРёСЏ: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 
