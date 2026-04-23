import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PartnerSettingsController.dart';
import 'package:backend/services/PartnerSettingsService.dart';
import 'package:backend/model/entities/PartnerSettings.dart';

import 'PartnerSettingsControllerTest.mocks.dart';

@GenerateMocks([PartnerSettingsService])
void main() {
  late MockPartnerSettingsService service;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    service = MockPartnerSettingsService();
    handler = PartnerSettingsController(service).router.call;
  });

  PartnerSettings _settings({int id = 1}) => PartnerSettings(
    id: id,
    partnerId: 1,
    brandingColor: '#FF0000',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  Request _get(String path) =>
      Request('GET', Uri.parse('http://localhost/$path'));

  Request _post(String path, Map<String, dynamic> body) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  Request _put(String path, Map<String, dynamic> body) =>
      Request('PUT', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  Request _delete(String path) =>
      Request('DELETE', Uri.parse('http://localhost/$path'));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список настроек', () async {
      when(service.getAllSettings()).thenAnswer((_) async => [_settings()]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает настройки', () async {
      when(service.getSettings(1)).thenAnswer((_) async => _settings());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если настройки не найдены', () async {
      when(service.getSettings(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('400 если отсутствуют обязательные поля', () async {
      final resp = await handler(_post('', {'partner_id': 1}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при корректном создании', () async {
      when(service.createSettings(1, '#FF0000')).thenAnswer((_) async => _settings());
      final resp = await handler(_post('', {'partner_id': 1, 'branding_color': '#FF0000'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('200 при обновлении', () async {
      when(service.updateSettings(1, any)).thenAnswer((_) async => _settings());
      final resp = await handler(_put('1', {'branding_color': '#00FF00'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('200 при удалении', () async {
      when(service.deleteSettings(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 200);
    });
  });
}
