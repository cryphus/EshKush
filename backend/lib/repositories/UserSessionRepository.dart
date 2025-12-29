import 'package:postgres/postgres.dart';
import '../model/entities/UserSessions.dart';
import '../model/enums/SessionStatus.dart';

class UserSessionRepository {
  final PostgreSQLConnection _connection;

  UserSessionRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      if (results.isEmpty) return null;
      return results.first.values.first;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
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
      print('Ошибка поиска сессии по ID: $e');
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
      print('Ошибка поиска сессий пользователя: $e');
      rethrow;
    }
  }

  Future<UserSessions> create(UserSessions session) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO user_sessions (
          user_id, token, device_info, ip_address, status, expires_at, created_at
        )
        VALUES (
          @userId, @token, @deviceInfo, @ipAddress, @status::session_status, @expiresAt, @createdAt
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
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания сессии');
      }
      return UserSessions.fromJson(result);
    } catch (e) {
      print('Ошибка создания сессии: $e');
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
          status = @status::session_status
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': session.id,
          'expiresAt': session.expiresAt,
          'status': session.status.toString().split('.').last,
        },
      );
      if (result == null) {
        throw Exception('Сессия не найдена');
      }
      return UserSessions.fromJson(result);
    } catch (e) {
      print('Ошибка обновления сессии: $e');
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
      print('Ошибка удаления сессии: $e');
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
      print('Ошибка получения активных сессий: $e');
      rethrow;
    }
  }

  Future<void> terminateAllUserSessions(int userId) async {
    try {
      await queryOne(
        '''
        UPDATE user_sessions 
        SET status = 'revoked'::session_status
        WHERE user_id = @userId AND status = 'active'
        ''',
        params: {'userId': userId},
      );
    } catch (e) {
      print('Ошибка завершения всех сессий пользователя: $e');
      rethrow;
    }
  }
} 