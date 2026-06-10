import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PromoCodesController.dart';
import 'package:backend/services/PromoCodesService.dart';
import 'package:backend/model/entities/PromoCodes.dart';
import 'package:backend/model/enums/DiscountType.dart';

import 'PromoCodesControllerTest.mocks.dart';

@GenerateMocks([PromoCodesService])
void main() {
  late MockPromoCodesService promoService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    promoService = MockPromoCodesService();
    handler = PromoCodesController(promoService).router.call;
  });

  PromoCodes _promo({int id = 1, String code = 'SAVE10'}) => PromoCodes(
    id: id,
    code: code,
    description: 'Test promo',
    discountType: DiscountType.percentage,
    discountValue: 10.0,
    minOrderSum: 100.0,
    startDate: DateTime(2020),
    endDate: DateTime(2099),
    isActive: true,
    currentUsage: 0,
    applicableProducts: [],
    applicablePoints: [],
  );

  final _adminUser = <String, Object>{'id': 1, 'role': 'admin'};
  final _regularUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  Request _delete(String path, {Map<String, Object>? user}) =>
      Request('DELETE', Uri.parse('http://localhost/$path'), context: _ctx(user));

  // ── GET / (active) ────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает активные промокоды без авторизации', () async {
      when(promoService.getActivePromoCodes()).thenAnswer((_) async => [_promo()]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 1);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_get('1', user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(promoService.getPromoCodeById(1)).thenAnswer((_) async => _promo());
      final resp = await handler(_get('1', user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /calculate ───────────────────────────────────────────────────────
  group('POST /calculate', () {
    test('400 если нет code или orderSum', () async {
      final resp = await handler(_post('calculate', {'code': 'SAVE10'}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при корректном запросе', () async {
      when(promoService.calculateDiscount('SAVE10', 200.0, null, null))
          .thenAnswer((_) async => 20.0);
      final resp = await handler(_post('calculate', {
        'code': 'SAVE10',
        'orderSum': 200.0,
      }));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['discount'], 20.0);
    });
  });

  // ── POST / (create) ───────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'code': 'NEW10'}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_post('', {'code': 'NEW10'}, user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin с валидными данными', () async {
      when(promoService.createPromoCode(
        code: anyNamed('code'),
        description: anyNamed('description'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        minOrderSum: anyNamed('minOrderSum'),
        discountType: anyNamed('discountType'),
        discountValue: anyNamed('discountValue'),
        isActive: anyNamed('isActive'),
        usageLimit: anyNamed('usageLimit'),
        applicableProducts: anyNamed('applicableProducts'),
        applicablePoints: anyNamed('applicablePoints'),
      )).thenAnswer((_) async => _promo(code: 'NEW10'));
      final resp = await handler(_post('', {
        'code': 'NEW10',
        'description': 'Test',
        'discount_type': 'percentage',
        'discount_value': 10.0,
        'min_order_sum': 50.0,
        'start_date': '2024-01-01T00:00:00.000',
        'end_date': '2099-12-31T00:00:00.000',
        'usage_limit': 100,
      }, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_delete('1', user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(promoService.deletePromoCode(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1', user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });
}
