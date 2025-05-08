import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PartnerSettingsService.dart';

class PartnerSettingsController {
  final PartnerSettingsService _settingsService;

  PartnerSettingsController(this._settingsService);

  Future<Response> getSettings(Request request, String id) async {
    try {
      final settingsId = int.parse(id);
      final settings = await _settingsService.getSettings(settingsId);
      
      if (settings == null) {
        return Response.notFound(
          jsonEncode({'error': 'Настройки не найдены'}),
          headers: _getCorsHeaders(),
        );
      }

      return Response.ok(
        jsonEncode(settings.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getSettingsByPartnerId(Request request, String partnerId) async {
    try {
      final id = int.parse(partnerId);
      final settings = await _settingsService.getSettingsByPartnerId(id);
      
      if (settings == null) {
        return Response.notFound(
          jsonEncode({'error': 'Настройки не найдены'}),
          headers: _getCorsHeaders(),
        );
      }

      return Response.ok(
        jsonEncode(settings.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createSettings(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      
      if (data['partner_id'] == null || data['branding_color'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      final settings = await _settingsService.createSettings(
        data['partner_id'],
        data['branding_color'],
      );

      return Response.ok(
        jsonEncode(settings.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка создания настроек: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateSettings(Request request, String id) async {
    try {
      final settingsId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      
      final updatedSettings = await _settingsService.updateSettings(settingsId, data);
      return Response.ok(
        jsonEncode(updatedSettings.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка обновления настроек: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateBrandingColor(Request request, String id) async {
    try {
      final settingsId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      
      if (data['branding_color'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'Отсутствует цвет брендинга'}),
          headers: _getCorsHeaders(),
        );
      }

      final updatedSettings = await _settingsService.updateBrandingColor(
        settingsId,
        data['branding_color'],
      );
      
      return Response.ok(
        jsonEncode(updatedSettings.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка обновления цвета брендинга: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> deleteSettings(Request request, String id) async {
    try {
      final settingsId = int.parse(id);
      await _settingsService.deleteSettings(settingsId);
      return Response.ok(
        jsonEncode({'message': 'Настройки успешно удалены'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка удаления настроек: $e'}),
        headers: _getCorsHeaders(),
      );
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