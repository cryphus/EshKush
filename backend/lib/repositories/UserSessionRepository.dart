import 'package:postgres/postgres.dart';
import '../model/entities/UserSessions.dart';

class UserSessionRepository {
  final PostgreSQLConnection _connection;

  UserSessionRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      if (results.isEmpty) return null;
      return results.first.values.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM user_sessions WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : UserSessions.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserSessions>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM user_sessions WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => UserSessions.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions> create(UserSessions session) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO user_sessions (
          user_id, token, refresh_jti_hash, device_info, ip_address, status, expires_at, created_at
        )
        VALUES (
          @userId, @token, @refreshJtiHash, @deviceInfo, @ipAddress, @status::session_status, @expiresAt, @createdAt
        )
        RETURNING *
        ''',
        params: {
          'userId': session.userId,
          'createdAt': session.createdAt,
          'expiresAt': session.expiresAt,
          'deviceInfo': session.userAgent.isNotEmpty ? session.userAgent : (session.deviceId ?? ''),
          'ipAddress': session.ipAddress,
          'status': session.status.toString().split('.').last,
          'token': (session.token != null && session.token!.length > 255)
              ? session.token!.substring(0, 255)
              : session.token,
          'refreshJtiHash': session.refreshJtiHash,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания сессии');
      }
      return UserSessions.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserSessions> update(UserSessions session) async {
    try {
      final result = await queryOne(
        '''
        UPDATE user_sessions 
        SET 
          expires_at = @expiresAt,
          status = @status::session_status,
          refresh_jti_hash = @refreshJtiHash,
          last_active = @lastActive,
          is_active = @isActive
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': session.id,
          'expiresAt': session.expiresAt,
          'status': session.status.toString().split('.').last,
          'refreshJtiHash': session.refreshJtiHash,
          'lastActive': session.lastActive,
          'isActive': session.isActive,
        },
      );
      if (result == null) {
        throw Exception('Сессия не найдена');
      }
      return UserSessions.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM user_sessions WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Сессия не найдена');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Проверка, что jti в blacklist (отозван при logout/terminate).
  Future<bool> isBlacklisted(String jtiHash) async {
    try {
      final result = await queryOne(
        '''
        SELECT 1 FROM token_blacklist
        WHERE jti_hash = @jtiHash AND expires_at > NOW()
        LIMIT 1
        ''',
        params: {'jtiHash': jtiHash},
      );
      return result != null;
    } catch (e) {
      return true;
    }
  }

  Future<void> addToBlacklist(String jtiHash, DateTime expiresAt) async {
    try {
      await queryOne(
        '''
        INSERT INTO token_blacklist (jti_hash, expires_at)
        VALUES (@jtiHash, @expiresAt)
        ON CONFLICT (jti_hash) DO UPDATE SET expires_at = EXCLUDED.expires_at
        RETURNING jti_hash
        ''',
        params: {'jtiHash': jtiHash, 'expiresAt': expiresAt},
      );
    } catch (e) {
    }
  }

  Future<void> addManyToBlacklist(List<String> jtiHashes, DateTime expiresAt) async {
    try {
      await queryOne(
        '''
        INSERT INTO token_blacklist (jti_hash, expires_at)
        SELECT UNNEST(@hashes::text[]), @expiresAt
        ON CONFLICT (jti_hash) DO UPDATE SET expires_at = EXCLUDED.expires_at
        RETURNING jti_hash
        ''',
        params: {'hashes': jtiHashes, 'expiresAt': expiresAt},
      );
    } catch (e) {
    }
  }

  Future<UserSessions?> findActiveByRefreshJtiHash(String refreshJtiHash) async {
    try {
      if (await isBlacklisted(refreshJtiHash)) return null;
      final result = await queryOne(
        '''
        SELECT * FROM user_sessions
        WHERE refresh_jti_hash = @refreshJtiHash
          AND status = 'active'
          AND is_active = TRUE
          AND expires_at > NOW()
        ORDER BY created_at DESC
        LIMIT 1
        ''',
        params: {'refreshJtiHash': refreshJtiHash},
      );
      return result == null ? null : UserSessions.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revokeByRefreshJtiHash(String refreshJtiHash) async {
    try {
      await queryOne(
        '''
        UPDATE user_sessions
        SET status = 'revoked', is_active = FALSE, expires_at = NOW()
        WHERE refresh_jti_hash = @refreshJtiHash
        RETURNING id
        ''',
        params: {'refreshJtiHash': refreshJtiHash},
      );
      final blacklistExpires = DateTime.now().add(const Duration(days: 8));
      await addToBlacklist(refreshJtiHash, blacklistExpires);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserSessions>> getActiveSessions() async {
    try {
      final results = await query(
        'SELECT * FROM user_sessions WHERE is_active = true AND status = \'active\'',
      );
      return results.map((map) => UserSessions.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> terminateAllUserSessions(int userId) async {
    try {
      final sessions = await query(
        '''
        SELECT refresh_jti_hash FROM user_sessions
        WHERE user_id = @userId AND status = 'active' AND is_active = TRUE
        ''',
        params: {'userId': userId},
      );
      final blacklistExpires = DateTime.now().add(const Duration(days: 8));
      final hashes = sessions
          .map((r) => r['refresh_jti_hash']?.toString())
          .where((h) => h != null && h.isNotEmpty)
          .cast<String>()
          .toList();
      if (hashes.isNotEmpty) {
        await addManyToBlacklist(hashes, blacklistExpires);
      }
      await queryOne(
        '''
        UPDATE user_sessions
        SET status = 'revoked'::session_status, is_active = FALSE, expires_at = NOW()
        WHERE user_id = @userId AND status = 'active'
        RETURNING id
        ''',
        params: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLastActive(int sessionId) async {
    try {
      await queryOne(
        '''
        UPDATE user_sessions SET last_active = NOW() WHERE id = @id
        RETURNING id
        ''',
        params: {'id': sessionId},
      );
    } catch (e) {
    }
  }

  /// Удаление истёкших сессий (TTL/auto-expire cleanup).
  Future<int> cleanupExpiredSessions() async {
    try {
      return await _connection.execute(
        'DELETE FROM user_sessions WHERE expires_at < NOW()',
      );
    } catch (e) {
      return 0;
    }
  }

  /// Удаление записей из blacklist с истёкшим expires_at.
  Future<void> cleanupExpiredBlacklist() async {
    try {
      await _connection.execute(
        'DELETE FROM token_blacklist WHERE expires_at < NOW()',
      );
    } catch (e) {
    }
  }
} 