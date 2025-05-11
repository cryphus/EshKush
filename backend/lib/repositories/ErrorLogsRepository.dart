import 'package:postgres/postgres.dart';
import '../model/entities/ErrorLogs.dart';
import '../model/enums/ErrorSeverity.dart';

class ErrorLogsRepository {
  final PostgreSQLConnection _connection;

  ErrorLogsRepository(this._connection);

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

  Future<ErrorLogs> create(ErrorLogs error) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO error_logs (
          error_message, error_code, stack_trace, time, severity,
          module, user_id, additional_info, resolved, resolved_at,
          resolved_by
        )
        VALUES (
          @errorMessage, @errorCode, @stackTrace, @time,
          @severity::error_severity, @module, @userId, @additionalInfo,
          @resolved, @resolvedAt, @resolvedBy
        )
        RETURNING *
        ''',
        params: {
          'errorMessage': error.errorMessage,
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
      print('Ошибка создания лога ошибки: $e');
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
      print('Ошибка поиска логов по уровню серьезности: $e');
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
      print('Ошибка поиска логов по модулю: $e');
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
      print('Ошибка поиска логов по ID пользователя: $e');
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
      print('Ошибка поиска нерешенных логов: $e');
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
      print('Ошибка получения последних логов: $e');
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
      print('Ошибка отметки лога как решенного: $e');
      rethrow;
    }
  }
} 