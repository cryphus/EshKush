import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/ActionLog.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';

class ActionLogRepository extends BaseRepository {
  final PostgreSQLConnection _connection;

  ActionLogRepository(this._connection) : super(_connection);

  Future<ActionLog> create(ActionLog log) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO action_logs (
          user_id, action_type, entity_type, entity_id, details,
          timestamp, ip_address, user_agent, location, is_success,
          error_message, metadata
        )
        VALUES (
          @userId, @actionType::action_type, @entityType::entity_type,
          @entityId, @details, @timestamp, @ipAddress, @userAgent,
          @location, @isSuccess, @errorMessage, @metadata
        )
        RETURNING *
        ''',
        params: {
          'userId': log.userId,
          'actionType': log.actionType.toString().split('.').last,
          'entityType': log.targetEntity.toString().split('.').last,
          'entityId': log.targetId,
          'details': log.details,
          'timestamp': log.timestamp,
          'ipAddress': log.ipAddress,
          'userAgent': log.userAgent,
          'location': log.location,
          'isSuccess': log.isSuccess,
          'errorMessage': log.errorMessage,
          'metadata': log.metadata,
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания лога действия');
      }

      return ActionLog.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ActionLog>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM action_logs WHERE user_id = @userId ORDER BY timestamp DESC',
        params: {'userId': userId},
      );
      return results.map((map) => ActionLog.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ActionLog>> findByEntity(
      EntityType entityType, int entityId) async {
    try {
      final results = await query(
        '''
        SELECT * FROM action_logs 
        WHERE entity_type = @entityType::entity_type 
        AND entity_id = @entityId 
        ORDER BY timestamp DESC
        ''',
        params: {
          'entityType': entityType.toString().split('.').last,
          'entityId': entityId,
        },
      );
      return results.map((map) => ActionLog.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ActionLog>> findByActionType(ActionType actionType) async {
    try {
      final results = await query(
        'SELECT * FROM action_logs WHERE action_type = @actionType::action_type ORDER BY timestamp DESC',
        params: {'actionType': actionType.toString().split('.').last},
      );
      return results.map((map) => ActionLog.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ActionLog>> findRecent({int limit = 100}) async {
    try {
      final results = await query(
        'SELECT * FROM action_logs ORDER BY timestamp DESC LIMIT @limit',
        params: {'limit': limit},
      );
      return results.map((map) => ActionLog.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
