import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PartnerController.dart';
import 'package:backend/services/PartnerService.dart';
import 'package:backend/model/entities/Partner.dart';

import 'PartnerControllerTest.mocks.dart';

@GenerateMocks([PartnerService])
void main() {
  late MockPartnerService partnerService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    partnerService = MockPartnerService();
    handler = PartnerController(partnerService).router.call;
  });

  Partner _partner({int id = 1}) => Partner(
    id: id,
    userId: 1,
    name: 'Test Partner',
    maxDiscount: 10.0,
    createdAt: DateTime(2024),
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
    test('200 возвращает список партнёров', () async {
      when(partnerService.getAllPartners())
          .thenAnswer((_) async => [_partner(), _partner(id: 2)]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 2);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает партнёра', () async {
      when(partnerService.getPartner(1)).thenAnswer((_) async => _partner());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если партнёр не найден', () async {
      when(partnerService.getPartner(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('200 при создании партнёра', () async {
      when(partnerService.createPartner(any)).thenAnswer((_) async => _partner());
      final resp = await handler(_post('', {
        'user_id': 1,
        'name': 'Test Partner',
        'contact_document': 'doc123',
      }));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('200 при обновлении', () async {
      when(partnerService.updatePartner(1, any))
          .thenAnswer((_) async => _partner());
      final resp = await handler(_put('1', {'name': 'Updated', 'user_id': 1}));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('200 при удалении', () async {
      when(partnerService.deletePartner(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 200);
    });
  });
}
