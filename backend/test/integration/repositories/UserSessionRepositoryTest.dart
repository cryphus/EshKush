import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/model/enums/SessionStatus.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late UserSessionRepository repo;
  late int userId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = UserSessionRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['token_blacklist', 'user_sessions']));

  tearDownAll(() async => TestDb.close());

  final _now = DateTime.now();
  final _expires = DateTime.now().add(const Duration(days: 7));

  UserSessions _session({
    String jtiHash = 'testhash001',
    SessionStatus status = SessionStatus.active,
  }) =>
      UserSessions(
        id: 0,
        userId: userId,
        createdAt: _now,
        expiresAt: _expires,
        lastActive: _now,
        userAgent: 'TestAgent/1.0',
        ipAddress: '127.0.0.1',
        status: status,
        refreshJtiHash: jtiHash,
        token: 'tok_$jtiHash',
        isActive: status == SessionStatus.active,
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт сессию с id > 0', () async {
      final result = await repo.create(_session());
      expect(result.id, greaterThan(0));
      expect(result.userId, userId);
    });

    test('статус active по умолчанию', () async {
      final result = await repo.create(_session());
      expect(result.status, SessionStatus.active);
    });

    test('сохраняет refreshJtiHash', () async {
      final result = await repo.create(_session(jtiHash: 'uniquehash123'));
      expect(result.refreshJtiHash, 'uniquehash123');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает сессию по id', () async {
      final created = await repo.create(_session(jtiHash: 'findbyid001'));
      final found = await repo.findById(created.id);
      expect(found?.userId, userId);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает сессии пользователя', () async {
      await repo.create(_session(jtiHash: 'hash_a'));
      await repo.create(_session(jtiHash: 'hash_b'));
      final sessions = await repo.findByUserId(userId);
      expect(sessions.length, 2);
    });

    test('возвращает пустой список для пользователя без сессий', () async {
      expect(await repo.findByUserId(999999), isEmpty);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет сессию', () async {
      final created = await repo.create(_session(jtiHash: 'del_hash'));
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если сессия не найдена', () async {
      expect(() => repo.delete(999999), throwsA(isA<Exception>()));
    });
  });

  // ── blacklist ─────────────────────────────────────────────────────────────
  group('addToBlacklist / isBlacklisted', () {
    test('добавленный jti считается blacklisted', () async {
      const jti = 'blacklisted_jti_001';
      await repo.addToBlacklist(jti, DateTime.now().add(const Duration(days: 1)));
      expect(await repo.isBlacklisted(jti), isTrue);
    });

    test('не добавленный jti не blacklisted', () async {
      expect(await repo.isBlacklisted('not_blacklisted_001'), isFalse);
    });
  });

  // ── terminateAllUserSessions ──────────────────────────────────────────────
  group('terminateAllUserSessions', () {
    test('отзывает все активные сессии пользователя', () async {
      await repo.create(_session(jtiHash: 'term_a'));
      await repo.create(_session(jtiHash: 'term_b'));
      await repo.terminateAllUserSessions(userId);
      final sessions = await repo.findByUserId(userId);
      expect(sessions.every((s) => !s.isActive), isTrue);
    });
  });
}
