import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/UserFavoriteController.dart';
import 'package:backend/services/UserFavoriteService.dart';
import 'package:backend/model/entities/UserFavorite.dart';

import 'UserFavoriteControllerTest.mocks.dart';

@GenerateMocks([UserFavoriteService])
void main() {
  late MockUserFavoriteService favoriteService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    favoriteService = MockUserFavoriteService();
    handler = UserFavoriteController(favoriteService).router.call;
  });

  UserFavorite _favorite({int userId = 1, int pointId = 1}) =>
      UserFavorite(userId: userId, pointId: pointId, createdAt: DateTime(2024));

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

  Request _delete(String path, {Map<String, Object>? user}) =>
      Request('DELETE', Uri.parse('http://localhost/$path'), context: _ctx(user));

  // ── GET / (my favorites) ──────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает список избранного', () async {
      when(favoriteService.getByUserId(1)).thenAnswer((_) async => [_favorite()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST / (add to favorites) ─────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'point_id': 1}));
      expect(resp.statusCode, 401);
    });

    test('400 если point_id некорректен', () async {
      final resp = await handler(_post('', {'point_id': 0}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при добавлении в избранное', () async {
      when(favoriteService.addToFavorites(any)).thenAnswer((_) async => _favorite());
      final resp = await handler(_post('', {'point_id': 1}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<pointId> ─────────────────────────────────────────────────────
  group('DELETE /<pointId>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 401);
    });

    test('400 если pointId некорректен', () async {
      final resp = await handler(_delete('0', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при удалении из избранного', () async {
      when(favoriteService.removeFromFavorites(1, 1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /is-favorite/<pointId> ────────────────────────────────────────────
  group('GET /is-favorite/<pointId>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('is-favorite/1'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает результат проверки', () async {
      when(favoriteService.isFavorite(1, 1)).thenAnswer((_) async => true);
      final resp = await handler(_get('is-favorite/1', user: _authUser));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['isFavorite'], true);
    });
  });

  // ── GET /point/<pointId> ──────────────────────────────────────────────────
  group('GET /point/<pointId>', () {
    test('200 без авторизации', () async {
      when(favoriteService.getByPointId(1)).thenAnswer((_) async => [_favorite()]);
      final resp = await handler(_get('point/1'));
      expect(resp.statusCode, 200);
    });

    test('400 при некорректном pointId', () async {
      final resp = await handler(_get('point/0'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });
}
