import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PointController.dart';
import 'package:backend/services/PointService.dart';
import 'package:backend/model/entities/Point.dart';
import 'package:backend/model/entities/PointReview.dart';

import 'PointControllerTest.mocks.dart';

@GenerateMocks([PointService])
void main() {
  late MockPointService pointService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    pointService = MockPointService();
    handler      = PointController(pointService).router.call;
  });

  // ─── fixtures ────────────────────────────────────────────────────────────
  Point _point({int id = 1}) => Point(
    id: id, name: 'Test Point', address: 'ул. Пушкина 1', cityId: 1,
    products: {}, openingHours: '09:00', closingHours: '21:00',
    partnerId: 1, longitude: 37.6, latitude: 55.7,
    tags: {}, createdAt: DateTime(2024),
  );

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request(
        'POST', Uri.parse('http://localhost/$path'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
        context: _ctx(user),
      );

  Request _delete(String path, {Map<String, Object>? user}) =>
      Request('DELETE', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _put(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request(
        'PUT', Uri.parse('http://localhost/$path'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
        context: _ctx(user),
      );

  final _adminUser = <String, Object>{'id': 1, 'role': 'admin'};
  final _regularUser = <String, Object>{'id': 1, 'role': 'user'};

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список точек', () async {
      when(pointService.getAllPoints(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_point(id: 1), _point(id: 2)]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect((body['data'] as List).length, 2);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает точку по id', () async {
      when(pointService.getPointById(1)).thenAnswer((_) async => _point());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('400 при нечисловом id', () async {
      final resp = await handler(_get('abc'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('404 если точка не найдена', () async {
      when(pointService.getPointById(99)).thenThrow(Exception('Точка не найдена'));
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'name': 'New'}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя (не admin)', () async {
      final resp = await handler(_post('', {'name': 'New'}, user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin с валидными данными', () async {
      when(pointService.createPoint(any)).thenAnswer((_) async => _point());
      final resp = await handler(_post('', {
        'name': 'New Point',
        'address': 'ул. Тест 1',
        'city_id': 1,
        'partner_id': 1,
        'longitude': 37.6,
        'latitude': 55.7,
        'opening_hours': '09:00',
        'closing_hours': '21:00',
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
      when(pointService.deletePoint(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1', user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id>/rating ───────────────────────────────────────────────────────
  group('PUT /<id>/rating', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('1/rating', {'rating': 4.0}));
      expect(resp.statusCode, 401);
    });

    test('400 при отсутствующем рейтинге', () async {
      final resp = await handler(_put('1/rating', {}, user: _regularUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('400 при рейтинге > 5', () async {
      final resp = await handler(_put('1/rating', {'rating': 6.0}, user: _regularUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при валидном рейтинге', () async {
      when(pointService.updateRating(1, 4.0)).thenAnswer((_) async {});
      final resp = await handler(_put('1/rating', {'rating': 4.0}, user: _regularUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id>/reviews ──────────────────────────────────────────────────────
  group('GET /<id>/reviews', () {
    test('200 возвращает отзывы', () async {
      when(pointService.getPointReviews(1)).thenAnswer((_) async => [
        PointReview(id: 1, pointId: 1, userId: 1, createdAt: DateTime(2024), rating: 4.0),
      ]);
      final resp = await handler(_get('1/reviews'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 1);
    });
  });
}
