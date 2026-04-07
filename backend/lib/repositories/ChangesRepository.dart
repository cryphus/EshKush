import 'package:postgres/postgres.dart';
import '../model/entities/Changes.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';

class ChangesRepository {
  final PostgreSQLConnection _connection;

  ChangesRepository(this._connection);

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

  Future<Changes> create(Changes change) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO changes (
          entity_type, entity_id, field_name, old_value, new_value,
          changed_by, created_at, change_type, comment, is_reverted,
          reverted_at, reverted_by
        )
        VALUES (
          @entityType::entity_type, @entityId, @fieldName, @oldValue,
          @newValue, @changedBy, @createdAt, @changeType::change_type,
          @comment, @isReverted, @revertedAt, @revertedBy
        )
        RETURNING *
        ''',
        params: {
          'entityType': change.entityType.toString().split('.').last,
          'entityId': change.entityId,
          'fieldName': change.fieldName,
          'oldValue': change.oldValue,
          'newValue': change.newValue,
          'changedBy': change.changedBy,
          'createdAt': change.createdAt,
          'changeType': change.changeType.toString().split('.').last,
          'comment': change.comment,
          'isReverted': change.isReverted,
          'revertedAt': change.revertedAt,
          'revertedBy': change.revertedBy,
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания записи об изменении');
      }

      return Changes.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Changes>> findByEntity(EntityType entityType, int entityId) async {
    try {
      final results = await query(
        '''
        SELECT * FROM changes 
        WHERE entity_type = @entityType::entity_type 
        AND entity_id = @entityId 
        ORDER BY created_at DESC
        ''',
        params: {
          'entityType': entityType.toString().split('.').last,
          'entityId': entityId,
        },
      );
      return results.map((map) => Changes.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Changes>> findByUser(int userId) async {
    try {
      final results = await query(
        '''
        SELECT 
          id,
          entity_type,
          entity_id,
          change_type,
          field_name,
          old_value,
          new_value,
          changed_by,
          created_at
        FROM changes 
        WHERE changed_by = @userId 
        ORDER BY created_at DESC
        ''',
        params: {'userId': userId},
      );
      return results.map((map) => Changes.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Changes>> findByChangeType(ChangeType changeType) async {
    try {
      final results = await query(
        'SELECT * FROM changes WHERE change_type = @changeType::change_type ORDER BY created_at DESC',
        params: {'changeType': changeType.toString().split('.').last},
      );
      return results.map((map) => Changes.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Changes>> findRecent({int limit = 100}) async {
    try {
      final results = await query(
        'SELECT * FROM changes ORDER BY created_at DESC LIMIT @limit',
        params: {'limit': limit},
      );
      return results.map((map) => Changes.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revertChange(int changeId, int revertedBy, {String? comment}) async {
    try {
      await query(
        '''
        UPDATE changes 
        SET is_reverted = true, 
            reverted_at = NOW(), 
            reverted_by = @revertedBy,
            comment = @comment
        WHERE id = @changeId
        ''',
        params: {
          'changeId': changeId,
          'revertedBy': revertedBy,
          'comment': comment,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
} 