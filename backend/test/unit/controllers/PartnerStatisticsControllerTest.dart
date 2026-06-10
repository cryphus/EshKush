import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PartnerStatisticsController.dart';
import 'package:backend/services/PartnerStatisticsService.dart';
import 'package:backend/model/entities/PartnerStatistics.dart';

import 'PartnerStatisticsControllerTest.mocks.dart';

@GenerateMocks([PartnerStatisticsService])
void main() {
  late MockPartnerStatisticsService statsService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    statsService = MockPartnerStatisticsService();
    handler = PartnerStatisticsController(statsService).router.call;
  });

  PartnerStatistics _stats({int id = 1}) => PartnerStatistics(
    id: id,
    partnerId: 1,
    pointId: 1,
    totalOrders: 10,
    totalRevenue: 1000.0,
    totalCancel: 0,
    averageRating: 4.5,
    createdAt: DateTime(2024),
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией (возвращает подсказку)', () async {
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /one ──────────────────────────────────────────────────────────────
  group('GET /one', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('one'));
      expect(resp.statusCode, 401);
    });

    test('400 если id не указан', () async {
      final resp = await handler(_get('one', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает статистику', () async {
      when(statsService.getStatisticsById(1)).thenAnswer((_) async => _stats());
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/one?id=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-partner ───────────────────────────────────────────────────────
  group('GET /by-partner', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-partner'));
      expect(resp.statusCode, 401);
    });

    test('400 если partner_id не указан', () async {
      final resp = await handler(_get('by-partner', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает статистику партнёра', () async {
      when(statsService.getStatisticsByPartnerId(1)).thenAnswer((_) async => _stats());
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-partner?partner_id=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /by-point ─────────────────────────────────────────────────────────
  group('GET /by-point', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('by-point'));
      expect(resp.statusCode, 401);
    });

    test('400 если point_id не указан', () async {
      final resp = await handler(_get('by-point', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает статистику точки', () async {
      when(statsService.getStatisticsByPointId(1)).thenAnswer((_) async => _stats());
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/by-point?point_id=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /add-order ───────────────────────────────────────────────────────
  group('POST /add-order', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('add-order', {'id': 1, 'revenue': 100.0}));
      expect(resp.statusCode, 401);
    });

    test('400 если нет обязательных полей', () async {
      final resp = await handler(_post('add-order', {'id': 1}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при добавлении заказа', () async {
      when(statsService.addOrder(1, 100.0)).thenAnswer((_) async {});
      final resp = await handler(
          _post('add-order', {'id': 1, 'revenue': 100.0}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /add-cancel ──────────────────────────────────────────────────────
  group('POST /add-cancel', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('add-cancel', {'id': 1}));
      expect(resp.statusCode, 401);
    });

    test('200 при добавлении отмены', () async {
      when(statsService.addCancel(1)).thenAnswer((_) async {});
      final resp = await handler(_post('add-cancel', {'id': 1}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /update-rating ───────────────────────────────────────────────────
  group('POST /update-rating', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('update-rating', {'id': 1, 'rating': 4.5}));
      expect(resp.statusCode, 401);
    });

    test('400 если нет обязательных полей', () async {
      final resp = await handler(_post('update-rating', {'id': 1}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при обновлении рейтинга', () async {
      when(statsService.updateRating(1, 4.5)).thenAnswer((_) async {});
      final resp = await handler(
          _post('update-rating', {'id': 1, 'rating': 4.5}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
