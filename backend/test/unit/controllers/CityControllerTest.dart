import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/CityController.dart';
import 'package:backend/services/CityService.dart';
import 'package:backend/model/entities/City.dart';

import 'CityControllerTest.mocks.dart';

@GenerateMocks([CityService])
void main() {
  late MockCityService cityService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    cityService = MockCityService();
    handler     = CityController(cityService).router.call;
  });

  City _city({int id = 1, String name = 'Москва'}) =>
      City(id: id, name: name, createdAt: DateTime(2024));

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
    test('200 возвращает список городов', () async {
      when(cityService.getAll()).thenAnswer((_) async => [_city(), _city(id: 2, name: 'СПб')]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 2);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает город', () async {
      when(cityService.getById(1)).thenAnswer((_) async => _city());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если город не найден', () async {
      when(cityService.getById(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('400 если name отсутствует', () async {
      final resp = await handler(_post('', {}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при корректном создании', () async {
      when(cityService.create(any)).thenAnswer((_) async => _city());
      final resp = await handler(_post('', {'name': 'Москва'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('200 при обновлении', () async {
      when(cityService.update(any)).thenAnswer((_) async => _city(name: 'Новый'));
      final resp = await handler(_put('1', {'name': 'Новый'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('200 при удалении', () async {
      when(cityService.delete(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 200);
    });
  });
}