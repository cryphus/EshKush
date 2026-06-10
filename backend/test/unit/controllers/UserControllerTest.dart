import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/UserController.dart';
import 'package:backend/services/UserService.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/enums/UserRole.dart';

import 'UserControllerTest.mocks.dart';

@GenerateMocks([UserService])
void main() {
  late MockUserService userService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    userService = MockUserService();
    handler     = UserController(userService).router.call;
  });

  User _user({int id = 1, String username = 'testuser'}) => User(
    id: id, username: username, password: 'hash',
    number: '+79001234567', email: 'test@example.com',
    createdAt: DateTime(2024), role: UserRole.user,
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _put(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request(
        'PUT', Uri.parse('http://localhost/$path'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
        context: _ctx(user),
      );

  // ── GET /profile ──────────────────────────────────────────────────────────
  group('GET /profile', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('profile'));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(userService.getUserById(1)).thenAnswer((_) async => _user());
      final resp = await handler(_get('profile', user: _authUser));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['username'], 'testuser');
    });
  });

  // ── PUT /profile ──────────────────────────────────────────────────────────
  group('PUT /profile', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('profile', {'username': 'newname'}));
      expect(resp.statusCode, 401);
    });

    test('400 если нет полей для обновления', () async {
      final resp = await handler(_put('profile', {}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('403 если попытка изменить чужой профиль', () async {
      final resp = await handler(_put('profile', {'id': 99, 'username': 'other'}, user: _authUser));
      expect(resp.statusCode, 403);
    });

    test('200 при успешном обновлении', () async {
      when(userService.updateUser(1, any)).thenAnswer((_) async => _user(username: 'newname'));
      final resp = await handler(_put('profile', {'username': 'newname'}, user: _authUser));
      expect(resp.statusCode, 200);
    });
  });
}
