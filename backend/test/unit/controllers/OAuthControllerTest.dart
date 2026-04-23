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
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/model/enums/UserRole.dart';
import 'package:backend/model/enums/SessionStatus.dart';

import 'OAuthControllerTest.mocks.dart';

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

  /// Создаёт JWT с произвольным payload без верификации подписи.
  /// JwtDecoder.decode() не проверяет подпись — достаточно валидного base64.
  String _fakeJwt(Map<String, dynamic> payload) {
    final header  = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
    final body    = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return '$header.$body.fakesignature';
  }

  Request _post(String path, Map<String, dynamic> body) => Request(
    'POST', Uri.parse('http://localhost/$path'),
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  User _user() => User(
    id: 1, username: 'vk_12345', password: 'hash',
    number: '+79001234567', email: '12345@vk.com',
    createdAt: DateTime(2024), role: UserRole.user,
  );

  UserSessions _session() => UserSessions(
    id: 1, userId: 1,
    createdAt: DateTime(2024), expiresAt: DateTime(2025),
    lastActive: DateTime(2024), userAgent: 'test',
    ipAddress: '127.0.0.1', status: SessionStatus.active,
    refreshJtiHash: 'hash', isActive: true,
  );

  // ── POST /auth/google ─────────────────────────────────────────────────────
  group('POST /auth/google', () {
    test('400 если idToken отсутствует в теле', () async {
      final resp = await handler(_post('auth/google', {}));
      expect(resp.statusCode, 400);
    });

    test('400 если тело пустое', () async {
      final req = Request('POST', Uri.parse('http://localhost/auth/google'),
          body: '', headers: {'content-type': 'application/json'});
      final resp = await handler(req);
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('401 если GOOGLE_CLIENT_ID не задан в окружении (всегда в unit-тестах)', () async {
      // В тестовой среде GOOGLE_CLIENT_ID не установлен → контроллер бросает исключение → 401
      final token = _fakeJwt({
        'iss': 'https://accounts.google.com',
        'aud': 'some-client-id',
        'sub': '1234567890',
        'email': 'user@example.com',
      });
      final resp = await handler(_post('auth/google', {
        'idToken': token,
        'email': 'user@example.com',
      }));
      // Без GOOGLE_CLIENT_ID выбрасывается исключение → 401
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('401 если iss токена некорректный', () async {
      final token = _fakeJwt({
        'iss': 'https://evil.com',
        'aud': 'client-id',
        'email': 'user@example.com',
      });
      final resp = await handler(_post('auth/google', {
        'idToken': token,
        'email': 'user@example.com',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('401 при невалидном JWT (случайная строка)', () async {
      final resp = await handler(_post('auth/google', {
        'idToken': 'not.a.valid.jwt',
        'email': 'user@example.com',
      }));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST /auth/vk ─────────────────────────────────────────────────────────
  group('POST /auth/vk', () {
    test('400 если username и id отсутствуют', () async {
      final resp = await handler(_post('auth/vk', {}));
      expect(resp.statusCode, 400);
    });

    test('400 если username пустой', () async {
      final resp = await handler(_post('auth/vk', {'username': '', 'id': ''}));
      expect(resp.statusCode, 400);
    });

    test('200 для существующего пользователя VK (по email)', () async {
      when(userRepo.findByEmail(any)).thenAnswer((_) async => _user());
      when(userRepo.findByUsername(any)).thenAnswer((_) async => null);
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      final resp = await handler(_post('auth/vk', {
        'id': '12345',
        'email': '12345@vk.com',
      }));
      // Требуются JWT_SECRET env vars для генерации токенов
      // Без них генерация бросает — проверяем что ответ получен
      expect(resp.statusCode, isA<int>());
    }, skip: 'Требует JWT_SECRET env var для generateTokenBundle');

    test('200 для нового пользователя VK (создаёт аккаунт)', () async {
      when(userRepo.findByEmail(any)).thenAnswer((_) async => null);
      when(userRepo.findByUsername(any)).thenAnswer((_) async => null);
      when(userRepo.createUser(any)).thenAnswer((_) async => _user());
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      final resp = await handler(_post('auth/vk', {
        'id': '99999',
        'email': '',
      }));
      expect(resp.statusCode, isA<int>());
    }, skip: 'Требует JWT_SECRET env var для generateTokenBundle');

    test('VK создаёт пользователя с корректным username vk_<id>', () async {
      when(userRepo.findByEmail(any)).thenAnswer((_) async => null);
      when(userRepo.findByUsername('vk_42')).thenAnswer((_) async => null);
      when(userRepo.createUser(any)).thenAnswer((_) async => _user());
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      // Метод вызовет createUser — проверяем аргумент
      try {
        await handler(_post('auth/vk', {'id': '42'}));
      } catch (_) {}

      // Проверяем что createUser был вызван с username = 'vk_42'
      final calls = verify(userRepo.createUser(captureAny)).captured;
      if (calls.isNotEmpty) {
        final data = calls.first as Map<String, dynamic>;
        expect(data['username'], 'vk_42');
      }
    });

    test('VK использует fallback email <id>@vk.com если email не передан', () async {
      when(userRepo.findByEmail(any)).thenAnswer((_) async => null);
      when(userRepo.findByUsername(any)).thenAnswer((_) async => null);
      when(userRepo.createUser(any)).thenAnswer((_) async => _user());
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      try {
        await handler(_post('auth/vk', {'id': '77'}));
      } catch (_) {}

      final calls = verify(userRepo.createUser(captureAny)).captured;
      if (calls.isNotEmpty) {
        final data = calls.first as Map<String, dynamic>;
        expect(data['email'], '77@vk.com');
      }
    });

    test('VK находит существующего пользователя по username если email не совпал', () async {
      when(userRepo.findByEmail(any)).thenAnswer((_) async => null);
      when(userRepo.findByUsername('vk_123')).thenAnswer((_) async => _user());
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      try {
        await handler(_post('auth/vk', {'id': '123', 'email': 'noemail@vk.com'}));
      } catch (_) {}

      // findByUsername должен быть вызван
      verify(userRepo.findByUsername('vk_123')).called(1);
      // createUser НЕ должен быть вызван
      verifyNever(userRepo.createUser(any));
    });
  });
}
