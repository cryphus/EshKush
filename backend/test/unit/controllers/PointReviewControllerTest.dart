import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PointReviewController.dart';
import 'package:backend/services/PointReviewService.dart';
import 'package:backend/model/entities/PointReview.dart';

import 'PointReviewControllerTest.mocks.dart';

@GenerateMocks([PointReviewService])
void main() {
  late MockPointReviewService reviewService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    reviewService = MockPointReviewService();
    handler = PointReviewController(reviewService).router.call;
  });

  PointReview _review({int id = 1, int userId = 1}) => PointReview(
    id: id,
    pointId: 1,
    userId: userId,
    rating: 4.0,
    comment: 'Хорошее место',
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

  Request _put(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('PUT', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  Request _delete(String path, {Map<String, Object>? user}) =>
      Request('DELETE', Uri.parse('http://localhost/$path'), context: _ctx(user));

  // ── GET / (мои отзывы) ────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(reviewService.getByUserId(1)).thenAnswer((_) async => [_review()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /point/<pointId> ──────────────────────────────────────────────────
  group('GET /point/<pointId>', () {
    test('200 без авторизации', () async {
      when(reviewService.getByPointId(1)).thenAnswer((_) async => [_review()]);
      final resp = await handler(_get('point/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /user/<userId> ────────────────────────────────────────────────────
  group('GET /user/<userId>', () {
    test('200 без авторизации', () async {
      when(reviewService.getByUserId(1)).thenAnswer((_) async => [_review()]);
      final resp = await handler(_get('user/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает отзыв', () async {
      when(reviewService.getById(1)).thenAnswer((_) async => _review());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если не найден', () async {
      when(reviewService.getById(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'point_id': 1, 'rating': 4.0}));
      expect(resp.statusCode, 401);
    });

    test('200 при создании отзыва', () async {
      when(reviewService.create(any)).thenAnswer((_) async => _review());
      final resp = await handler(_post('', {
        'point_id': 1,
        'rating': 4.0,
        'comment': 'Хорошее место',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('1', {'rating': 5.0}));
      expect(resp.statusCode, 401);
    });

    test('404 если отзыв не найден', () async {
      when(reviewService.getById(99)).thenAnswer((_) async => null);
      final resp = await handler(_put('99', {'rating': 5.0}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при обновлении владельцем', () async {
      when(reviewService.getById(1)).thenAnswer((_) async => _review(userId: 1));
      when(reviewService.update(any)).thenAnswer((_) async => _review(userId: 1));
      final resp = await handler(_put('1', {'rating': 5.0}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 401);
    });

    test('404 если отзыв не найден', () async {
      when(reviewService.getById(99)).thenAnswer((_) async => null);
      final resp = await handler(_delete('99', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при удалении владельцем', () async {
      when(reviewService.getById(1)).thenAnswer((_) async => _review(userId: 1));
      when(reviewService.delete(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
