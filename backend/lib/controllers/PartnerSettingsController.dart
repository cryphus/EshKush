import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PartnerSettingsService.dart';
import 'package:shelf_router/shelf_router.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class PartnerSettingsController {
  final PartnerSettingsService _service;
  final Router _router = Router();

  PartnerSettingsController(this._service) {
    _router.get('/', _getAllSettings);
    _router.post('/', _createSettings);
    _router.get('/<id>', _getSettings);
    _router.put('/<id>', _updateSettings);
    _router.delete('/<id>', _deleteSettings);
  }

  Router get router => _router;

  Future<Response> _getSettings(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.parse(id);
      final settings = await _service.getSettings(settingsId);
      
      if (settings == null) {
        return Response.notFound(
          jsonEncode({'error': 'РќР°СЃС‚СЂРѕР№РєРё РЅРµ РЅР°Р№РґРµРЅС‹'}),
          headers: _getCorsHeaders(),
        );
      }

      final body = jsonEncode(settings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РЅР°СЃС‚СЂРѕРµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getAllSettings(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final settings = await _service.getAllSettings();
      final body = jsonEncode(settings.map((s) => s.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РЅР°СЃС‚СЂРѕРµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _createSettings(Request request) async {
    try {
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['partner_id'] == null || data['branding_color'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'РћС‚СЃСѓС‚СЃС‚РІСѓСЋС‚ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final settings = await _service.createSettings(
        data['partner_id'],
        data['branding_color'],
      );

      final body = jsonEncode(settings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РЅР°СЃС‚СЂРѕРµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateSettings(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.parse(id);
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      final updatedSettings = await _service.updateSettings(settingsId, data);
      final body = jsonEncode(updatedSettings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РЅР°СЃС‚СЂРѕРµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteSettings(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.parse(id);
      await _service.deleteSettings(settingsId);
      final body = jsonEncode({'message': 'РќР°СЃС‚СЂРѕР№РєРё СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅС‹'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РЅР°СЃС‚СЂРѕРµРє', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }
} 
