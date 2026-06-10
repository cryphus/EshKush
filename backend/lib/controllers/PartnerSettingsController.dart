import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PartnerSettingsService.dart';
import 'package:shelf_router/shelf_router.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestBodyUtils.dart';

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
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.tryParse(id);
      if (settingsId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID',
            code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
      final settings = await _service.getSettings(settingsId);

      if (settings == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Настройки не найдены',
            code: ErrorCode.notFound,
            headers: _getCorsHeaders());
      }

      final body = jsonEncode(settings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения настроек', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _getAllSettings(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final settings = await _service.getAllSettings();
      final body = jsonEncode(settings.map((s) => s.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения настроек', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _createSettings(Request request) async {
    try {
      final raw = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: RequestContextUtils.getRequestId(request));
      final data = RequestBodyUtils.decodeJsonObject(raw);

      if (data['partner_id'] == null || data['branding_color'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Отсутствуют обязательные поля',
            headers: _getCorsHeaders());
      }

      final settings = await _service.createSettings(
        data['partner_id'],
        data['branding_color'],
      );

      final body = jsonEncode(settings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания настроек', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _updateSettings(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.tryParse(id);
      if (settingsId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID',
            code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
      final raw = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, raw,
          requestId: RequestContextUtils.getRequestId(request));
      final data = RequestBodyUtils.decodeJsonObject(raw);

      final updatedSettings = await _service.updateSettings(settingsId, data);
      final body = jsonEncode(updatedSettings.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления настроек', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _deleteSettings(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));
      final settingsId = int.tryParse(id);
      if (settingsId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID',
            code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
      await _service.deleteSettings(settingsId);
      final body = jsonEncode({'message': 'Настройки успешно удалены'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body,
          requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления настроек', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
