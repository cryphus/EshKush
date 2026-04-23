import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/AuthController.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/UserSessionRepository.dart';

import 'AuthControllerTest.mocks.dart';

@GenerateMocks([AuthService, UserRepository, UserSessionRepository])
void main() {
  late MockAuthService authService;
  late MockUserRepository userRepo;
  late MockUserSessionRepository sessionRepo;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    authService = MockAuthService();
    userRepo    = MockUserRepository();
    sessionRepo = MockUserSessionRepository();
    handler     = AuthController(authService, userRepo, sessionRepo).router.call;
  });

  // ────────────────────────────────────────────────── helpers ───────────────
  Request _post(String path, Map<String, dynamic> body) => Request(
    'POST', Uri.parse('http://localhost/$path'),
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  Map<String, dynamic> _tokenResponse() => {
    'access_token': 'access.jwt.token',
    'refresh_token': 'refresh.jwt.token',
    'user': {'id': 1, 'username': 'testuser'},
  };

  // ── POST /auth/register ───────────────────────────────────────────────────
  group('POST /auth/register', () {
    test('200 при валидных данных', () async {
      when(authService.register(any, userAgent: anyNamed('userAgent'), ipAddress: anyNamed('ipAddress')))
          .thenAnswer((_) async => _tokenResponse());

      final resp = await handler(_post('auth/register', {
        'username': 'newuser',
        'email': 'new@example.com',
        'number': '+79001234567',
        'password': 'Pass1!xxxx',
        'password_confirm': 'Pass1!xxxx',
      }));
      expect(resp.statusCode, 200);
    });

    test('400/422 если отсутствует обязательное поле (username)', () async {
      final resp = await handler(_post('auth/register', {
        'email': 'new@example.com',
        'number': '+79001234567',
        'password': 'Pass1!xxxx',
        'password_confirm': 'Pass1!xxxx',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('400/422 если пароль не совпадает с подтверждением', () async {
      final resp = await handler(_post('auth/register', {
        'username': 'newuser',
        'email': 'new@example.com',
        'number': '+79001234567',
        'password': 'Pass1!xxxx',
        'password_confirm': 'DifferentPass1!',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('400/422 если пустой username', () async {
      final resp = await handler(_post('auth/register', {
        'username': '',
        'email': 'new@example.com',
        'number': '+79001234567',
        'password': 'Pass1!xxxx',
        'password_confirm': 'Pass1!xxxx',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('4xx если сервис бросает исключение (username занят)', () async {
      when(authService.register(any, userAgent: anyNamed('userAgent'), ipAddress: anyNamed('ipAddress')))
          .thenThrow(Exception('Пользователь уже существует'));

      final resp = await handler(_post('auth/register', {
        'username': 'existing',
        'email': 'ex@example.com',
        'number': '+79001234567',
        'password': 'Pass1!xxxx',
        'password_confirm': 'Pass1!xxxx',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST /login ───────────────────────────────────────────────────────────
  group('POST /login', () {
    test('200 при корректных credentials', () async {
      when(authService.login(any, any, userAgent: anyNamed('userAgent'), ipAddress: anyNamed('ipAddress')))
          .thenAnswer((_) async => _tokenResponse());

      final resp = await handler(_post('login', {
        'username': 'testuser',
        'password': 'Pass1!xxxx',
      }));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['access_token'], isNotNull);
    });

    test('400 если отсутствует username', () async {
      final resp = await handler(_post('login', {'password': 'Pass1!xxxx'}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('400 если пустой password', () async {
      final resp = await handler(_post('login', {'username': 'testuser', 'password': ''}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('4xx если сервис бросает (неверные credentials)', () async {
      when(authService.login(any, any, userAgent: anyNamed('userAgent'), ipAddress: anyNamed('ipAddress')))
          .thenThrow(Exception('Неверный логин или пароль'));

      final resp = await handler(_post('login', {
        'username': 'wronguser',
        'password': 'wrong',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST /auth/refresh ────────────────────────────────────────────────────
  group('POST /auth/refresh', () {
    test('200 при валидном refresh_token', () async {
      when(authService.refreshToken(any)).thenAnswer((_) async => _tokenResponse());

      final resp = await handler(_post('auth/refresh', {'refresh_token': 'valid.refresh.token'}));
      expect(resp.statusCode, 200);
    });

    test('4xx если сервис бросает (токен истёк/невалиден)', () async {
      when(authService.refreshToken(any)).thenThrow(Exception('Refresh token недействителен'));

      final resp = await handler(_post('auth/refresh', {'refresh_token': 'bad.token'}));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST /auth/check_user ─────────────────────────────────────────────────
  group('POST /auth/check_user', () {
    test('400 если номер телефона не передан', () async {
      final resp = await handler(_post('auth/check_user', {}));
      expect(resp.statusCode, 400);
    });

    test('400 если номер телефона пустой', () async {
      final resp = await handler(_post('auth/check_user', {'phoneNumber': ''}));
      expect(resp.statusCode, 400);
    });

    test('200 user exists: true если пользователь найден', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1, 'username': 'testuser'});

      final resp = await handler(_post('auth/check_user', {'phoneNumber': '+79001234567'}));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['exists'], true);
    });

    test('200 user exists: false если пользователь не найден', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => null);

      final resp = await handler(_post('auth/check_user', {'number': '+79009999999'}));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['exists'], false);
    });
  });
}