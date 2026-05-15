import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/model/enums/UserRole.dart';
import 'package:backend/model/enums/SessionStatus.dart';
import 'package:backend/utils/AppException.dart';

import '../../helpers/TestEnv.dart';
import 'AuthServiceTest.mocks.dart';

@GenerateMocks([UserRepository, UserSessionRepository])
void main() {
  late MockUserRepository userRepo;
  late MockUserSessionRepository sessionRepo;
  late AuthService sut;

  setUpAll(() {
    AppConfig.initForTesting();
  });

  setUp(() {
    userRepo    = MockUserRepository();
    sessionRepo = MockUserSessionRepository();
    sut = AuthService(userRepo, sessionRepo);
  });

  User _user({String username = 'testuser'}) => User(
    id: 1, username: username, password: 'hash',
    number: '+79001234567', email: 'test@example.com',
    createdAt: DateTime(2024), role: UserRole.user,
  );

  UserSessions _session() => UserSessions(
    id: 1, userId: 1,
    createdAt: DateTime(2024), expiresAt: DateTime(2025),
    lastActive: DateTime(2024), userAgent: 'test',
    ipAddress: '127.0.0.1', status: SessionStatus.active,
    refreshJtiHash: 'hash', isActive: true,
  );

  // ── register ──────────────────────────────────────────────────────────────────
  group('register', () {
    test('бросает если пользователь уже существует', () async {
      when(userRepo.findByUsername('testuser')).thenAnswer((_) async => _user());
      expect(
        () => sut.register({'username': 'testuser', 'email': 'a@b.com', 'number': '+79001234567', 'password': 'Pass1!xx', 'password_confirm': 'Pass1!xx', 'role': 'user'}),
        throwsA(isA<Exception>().having((e) => e.toString(), '', contains('уже существует'))),
      );
    });

    test('бросает при ошибках валидации (пустой username)', () async {
      expect(
        () => sut.register({'username': '', 'email': 'a@b.com', 'number': '+79001234567', 'password': 'Pass1!xx'}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешная регистрация возвращает токены и user', () async {
      when(userRepo.findByUsername('newuser')).thenAnswer((_) async => null);
      when(userRepo.createUser(any)).thenAnswer((_) async => _user(username: 'newuser'));
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      final result = await sut.register({
        'username': 'newuser', 'email': 'new@example.com',
        'number': '+79001234567', 'password': 'Pass1!xx',
        'password_confirm': 'Pass1!xx', 'role': 'user',
      });

      expect(result['access_token'], isNotNull);
      expect(result['refresh_token'], isNotNull);
      expect(result['user']['username'], 'newuser');
    }, skip: jwtEnvReady ? null : kJwtSkipReason);
  });

  // ── login ─────────────────────────────────────────────────────────────────────
  group('login', () {
    test('бросает при пустых credentials', () async {
      expect(() => sut.login('', 'pass'), throwsA(isA<Exception>()));
      expect(() => sut.login('user', ''), throwsA(isA<Exception>()));
    });

    test('бросает если пользователь не найден', () async {
      when(userRepo.authenticate('nouser', any)).thenAnswer((_) async => null);
      expect(
        () => sut.login('nouser', 'password'),
        throwsA(isA<Exception>().having((e) => e.toString(), '', contains('Неверный'))),
      );
    });

    test('блокирует логин после 5 неудачных попыток и на 6-й возвращает TooManyRequests', () async {
      when(userRepo.authenticate('nouser', any)).thenAnswer((_) async => null);

      for (var i = 0; i < 5; i++) {
        await expectLater(
          () => sut.login('nouser', 'password'),
          throwsA(isA<UnauthorizedException>()),
        );
      }

      await expectLater(
        () => sut.login('nouser', 'password'),
        throwsA(isA<TooManyRequestsException>()),
      );
    });

    test('после успешного логина счетчик неудачных попыток сбрасывается', () async {
      var call = 0;
      when(userRepo.authenticate('testuser', any)).thenAnswer((_) async {
        call++;
        if (call <= 4) return null;
        if (call == 5) return _user();
        return null;
      });
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      for (var i = 0; i < 4; i++) {
        await expectLater(
          () => sut.login('testuser', 'password'),
          throwsA(isA<UnauthorizedException>()),
        );
      }

      final loginResult = await sut.login('testuser', 'password');
      expect(loginResult['access_token'], isNotNull);

      await expectLater(
        () => sut.login('testuser', 'password'),
        throwsA(isA<UnauthorizedException>()),
      );
    }, skip: jwtEnvReady ? null : kJwtSkipReason);

    test('успешный логин возвращает токены', () async {
      when(userRepo.authenticate('testuser', any)).thenAnswer((_) async => _user());
      when(sessionRepo.create(any)).thenAnswer((_) async => _session());

      final result = await sut.login('testuser', 'password');
      expect(result['access_token'], isNotNull);
      expect(result['user']['username'], 'testuser');
    }, skip: jwtEnvReady ? null : kJwtSkipReason);
  });
}
