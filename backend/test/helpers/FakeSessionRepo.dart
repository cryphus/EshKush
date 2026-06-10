import 'package:backend/model/entities/UserSessions.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:postgres/postgres.dart';

/// Fake-репозиторий сессий для юнит-тестов SecurityMiddleware.
/// Не обращается к БД — хранит данные в памяти.
class FakeSessionRepository extends UserSessionRepository {
  final Map<String, UserSessions> _byJtiHash = {};
  final List<int> updatedSessionIds = [];

  FakeSessionRepository()
      : super(PostgreSQLConnection('test-host', 5432, 'test-db'));

  /// Добавляет сессию, которую вернёт [findActiveByRefreshJtiHash].
  void stub(String jtiHash, UserSessions session) {
    _byJtiHash[jtiHash] = session;
  }

  /// Очищает все заглушки и записи о вызовах.
  void reset() {
    _byJtiHash.clear();
    updatedSessionIds.clear();
  }

  @override
  Future<UserSessions?> findActiveByRefreshJtiHash(String refreshJtiHash) async {
    return _byJtiHash[refreshJtiHash];
  }

  @override
  Future<void> updateLastActive(int sessionId) async {
    updatedSessionIds.add(sessionId);
  }
}

/// Создаёт минимально валидный объект UserSessions для тестов.
UserSessions makeSession({
  int id = 1,
  int userId = 42,
  String refreshJtiHash = 'hash',
}) {
  final now = DateTime.now();
  return UserSessions(
    id: id,
    userId: userId,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
    lastActive: now,
    userAgent: 'test-agent',
    ipAddress: '127.0.0.1',
    refreshJtiHash: refreshJtiHash,
  );
}