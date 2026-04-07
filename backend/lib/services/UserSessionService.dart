import '../repositories/UserSessionRepository.dart';
import '../model/entities/UserSessions.dart';

class UserSessionService {
  final UserSessionRepository _sessionRepository;

  UserSessionService(this._sessionRepository);

  Future<UserSessions> getSessionById(int id) async {
    try {
      final session = await _sessionRepository.findById(id);
      if (session == null) {
        throw Exception('Сессия не найдена');
      }
      return session;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserSessions>> getUserSessions(int userId) async {
    try {
      return await _sessionRepository.findByUserId(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions?> getCurrentActiveSessionForUser(int userId) async {
    try {
      final sessions = await getUserSessions(userId);
      if (sessions.isEmpty) return null;
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sessions.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions> createSession({
    required int userId,
    required String userAgent,
    required String ipAddress,
    required String refreshJtiHash,
    String? deviceId,
    String? location,
    String? token,
    Duration sessionDuration = const Duration(days: 30),
  }) async {
    try {
      final now = DateTime.now();
      final session = UserSessions(
        id: 0, // ID будет присвоен базой данных
        userId: userId,
        createdAt: now,
        expiresAt: now.add(sessionDuration),
        lastActive: now,
        userAgent: userAgent,
        ipAddress: ipAddress,
        deviceId: deviceId,
        location: location,
        token: token,
        refreshJtiHash: refreshJtiHash,
      );
      return await _sessionRepository.create(session);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions> updateSession(UserSessions session) async {
    try {
      session.updateLastActive();
      return await _sessionRepository.update(session);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await _sessionRepository.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserSessions>> getActiveSessions() async {
    try {
      return await _sessionRepository.getActiveSessions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> terminateAllUserSessions(int userId) async {
    try {
      await _sessionRepository.terminateAllUserSessions(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> extendSession(UserSessions session, Duration duration) async {
    try {
      session.extendSession(duration);
      await _sessionRepository.update(session);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> terminateSession(UserSessions session) async {
    try {
      final jtiHash = session.refreshJtiHash;
      session.terminate();
      await _sessionRepository.update(session);
      await _sessionRepository.addToBlacklist(
        jtiHash,
        DateTime.now().add(const Duration(days: 8)),
      );
    } catch (e) {
      rethrow;
    }
  }
} 