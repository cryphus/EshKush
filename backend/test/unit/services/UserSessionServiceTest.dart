import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/UserSessionService.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/model/enums/SessionStatus.dart';

import 'UserSessionServiceTest.mocks.dart';

@GenerateMocks([UserSessionRepository])
void main() {
  late MockUserSessionRepository repo;
  late UserSessionService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockUserSessionRepository();
    sut  = UserSessionService(repo);
  });

  UserSessions _session({
    int id = 1,
    int userId = 1,
    DateTime? createdAt,
    String refreshJtiHash = 'hash123',
  }) {
    final now = createdAt ?? DateTime(2024);
    return UserSessions(
      id: id,
      userId: userId,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      lastActive: now,
      userAgent: 'test-agent',
      ipAddress: '127.0.0.1',
      status: SessionStatus.active,
      refreshJtiHash: refreshJtiHash,
    );
  }

  // ── getSessionById ─────────────────────────────────────────────────────────
  group('getSessionById', () {
    test('возвращает сессию по id', () async {
      when(repo.findById(1)).thenAnswer((_) async => _session());
      final result = await sut.getSessionById(1);
      expect(result.id, 1);
    });

    test('бросает если сессия не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getSessionById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getUserSessions ────────────────────────────────────────────────────────
  group('getUserSessions', () {
    test('возвращает список сессий пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_session(id: 1), _session(id: 2)]);
      final result = await sut.getUserSessions(1);
      expect(result.length, 2);
    });

    test('возвращает пустой список', () async {
      when(repo.findByUserId(99)).thenAnswer((_) async => []);
      expect(await sut.getUserSessions(99), isEmpty);
    });
  });

  // ── getCurrentActiveSessionForUser ─────────────────────────────────────────
  group('getCurrentActiveSessionForUser', () {
    test('возвращает null если нет сессий', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => []);
      final result = await sut.getCurrentActiveSessionForUser(1);
      expect(result, isNull);
    });

    test('возвращает самую новую сессию (сортировка по дате)', () async {
      final older = _session(id: 1, createdAt: DateTime(2024, 1));
      final newer = _session(id: 2, createdAt: DateTime(2024, 6));
      when(repo.findByUserId(1)).thenAnswer((_) async => [older, newer]);
      final result = await sut.getCurrentActiveSessionForUser(1);
      expect(result?.id, 2);
    });
  });

  // ── createSession ──────────────────────────────────────────────────────────
  group('createSession', () {
    test('делегирует в репозиторий с корректными данными', () async {
      when(repo.create(any)).thenAnswer((_) async => _session());
      final result = await sut.createSession(
        userId: 1,
        userAgent: 'Mozilla',
        ipAddress: '192.168.1.1',
        refreshJtiHash: 'jti-hash',
      );
      expect(result.id, 1);
      verify(repo.create(any)).called(1);
    });
  });

  // ── terminateSession ───────────────────────────────────────────────────────
  group('terminateSession', () {
    test('обновляет сессию и добавляет в blacklist', () async {
      final session = _session(refreshJtiHash: 'my-jti');
      when(repo.update(any)).thenAnswer((_) async => session);
      when(repo.addToBlacklist(any, any)).thenAnswer((_) async {});
      await sut.terminateSession(session);
      verify(repo.update(any)).called(1);
      verify(repo.addToBlacklist('my-jti', any)).called(1);
    });
  });

  // ── terminateAllUserSessions ───────────────────────────────────────────────
  group('terminateAllUserSessions', () {
    test('делегирует в репозиторий', () async {
      when(repo.terminateAllUserSessions(1)).thenAnswer((_) async {});
      await expectLater(sut.terminateAllUserSessions(1), completes);
      verify(repo.terminateAllUserSessions(1)).called(1);
    });
  });
}
