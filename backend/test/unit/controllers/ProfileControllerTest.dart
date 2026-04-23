import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ProfileController.dart';
import 'package:backend/services/ProfileService.dart';
import 'package:backend/model/entities/Profile.dart';

import 'ProfileControllerTest.mocks.dart';

@GenerateMocks([ProfileService])
void main() {
  late MockProfileService profileService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    profileService = MockProfileService();
    handler = ProfileController(profileService).router.call;
  });

  Profile _profile({int id = 1}) => Profile(
    id: id,
    userId: 1,
    firstName: 'Иван',
    lastName: 'Петров',
    sumCO2: 0,
    savedMoney: 0.0,
    countBuy: 0,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
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

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(profileService.getProfile(any)).thenAnswer((_) async => _profile());
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });

    test('404 если профиль не найден', () async {
      when(profileService.getProfile(any)).thenAnswer((_) async => null);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── GET /me ───────────────────────────────────────────────────────────────
  group('GET /me', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('me'));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(profileService.getProfile(any)).thenAnswer((_) async => _profile());
      final resp = await handler(_get('me', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 401);
    });

    test('200 возвращает профиль по id', () async {
      when(profileService.getProfileById(1)).thenAnswer((_) async => _profile());
      final resp = await handler(_get('1', user: _authUser));
      expect(resp.statusCode, 200);
    });

    test('404 если не найден', () async {
      when(profileService.getProfileById(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'first_name': 'Иван'}));
      expect(resp.statusCode, 401);
    });

    test('200 при создании профиля', () async {
      when(profileService.createProfile(any)).thenAnswer((_) async => _profile());
      final resp = await handler(_post('', {
        'first_name': 'Иван',
        'last_name': 'Петров',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('1', {'first_name': 'Иван'}));
      expect(resp.statusCode, 401);
    });

    test('200 при обновлении', () async {
      when(profileService.update(any)).thenAnswer((_) async => _profile());
      final resp = await handler(_put('1', {
        'first_name': 'Иван',
        'last_name': 'Петров',
      }, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE / ──────────────────────────────────────────────────────────────
  group('DELETE /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_delete(''));
      expect(resp.statusCode, 401);
    });

    test('200 при удалении', () async {
      when(profileService.deleteProfile(any)).thenAnswer((_) async {});
      final resp = await handler(_delete('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
