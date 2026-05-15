import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/ErrorLogs.dart';
import '../model/enums/ErrorSeverity.dart';

class ErrorLogsRepository extends BaseRepository {
  final PostgreSQLConnection _connection;

  ErrorLogsRepository(this._connection) : super(_connection);

  Future<ErrorLogs> create(ErrorLogs error) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO error_logs (
          message, error_code, stack_trace, time, severity,
          module, user_id, additional_info, resolved, resolved_at,
          resolved_by
        )
        VALUES (
          @message, @errorCode, @stackTrace, @time,
          @severity::error_severity, @module, @userId, @additionalInfo,
          @resolved, @resolvedAt, @resolvedBy
        )
        RETURNING *
        ''',
        params: {
          'message': error.errorMessage,
          'errorCode': error.errorCode,
          'stackTrace': error.stackTrace,
          'time': error.time,
          'severity': error.severity.toString().split('.').last,
          'module': error.module,
          'userId': error.userId,
          'additionalInfo': error.additionalInfo,
          'resolved': error.resolved,
          'resolvedAt': error.resolvedAt,
          'resolvedBy': error.resolvedBy,
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания лога ошибки');
      }

      return ErrorLogs.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ErrorLogs>> findBySeverity(ErrorSeverity severity) async {
    try {
      final results = await query(
        'SELECT * FROM error_logs WHERE severity = @severity::error_severity ORDER BY time DESC',
        params: {'severity': severity.toString().split('.').last},
      );
      return results.map((map) => ErrorLogs.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ErrorLogs>> findByModule(String module) async {
    try {
      final results = await query(
        'SELECT * FROM error_logs WHERE module = @module ORDER BY time DESC',
        params: {'module': module},
      );
      return results.map((map) => ErrorLogs.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ErrorLogs>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM error_logs WHERE user_id = @userId ORDER BY time DESC',
        params: {'userId': userId},
      );
      return results.map((map) => ErrorLogs.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ErrorLogs>> findUnresolved() async {
    try {
      final results = await query(
        'SELECT * FROM error_logs WHERE resolved = false ORDER BY time DESC',
      );
      return results.map((map) => ErrorLogs.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ErrorLogs>> findRecent({int limit = 100}) async {
    try {
      final results = await query(
        'SELECT * FROM error_logs ORDER BY time DESC LIMIT @limit',
        params: {'limit': limit},
      );
      return results.map((map) => ErrorLogs.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsResolved(int errorId, String resolvedBy) async {
    try {
      await query(
        '''
        UPDATE error_logs 
        SET resolved = true, 
            resolved_at = NOW(), 
            resolved_by = @resolvedBy
        WHERE id = @errorId
        ''',
        params: {
          'errorId': errorId,
          'resolvedBy': resolvedBy,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
