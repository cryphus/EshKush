import 'package:postgres/postgres.dart';
import '../model/entities/OrderActions.dart';
import '../model/enums/ActionType.dart';

class OrderActionsRepository {
  final PostgreSQLConnection _connection;

  OrderActionsRepository(this._connection);

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

  Future<OrderActions?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM order_actions WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : OrderActions.fromJson(result);
    } catch (e) {
      print('Ошибка поиска действия по ID: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> findByOrderId(int orderId) async {
    try {
      final results = await query(
        'SELECT * FROM order_actions WHERE order_id = @orderId',
        params: {'orderId': orderId},
      );
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска действий заказа: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> findByPartnerId(int partnerId) async {
    try {
      final results = await query(
        'SELECT * FROM order_actions WHERE partner_id = @partnerId',
        params: {'partnerId': partnerId},
      );
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска действий партнера: $e');
      rethrow;
    }
  }

  Future<OrderActions> create(OrderActions action) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO order_actions (
          order_id, partner_id, action_type, action_description,
          action_timestamp, updated_at, is_active
        )
        VALUES (
          @orderId, @partnerId, @actionType::action_type, @actionDescription,
          @actionTimestamp, @updatedAt, @isActive
        )
        RETURNING *
        ''',
        params: {
          'orderId': action.orderId,
          'partnerId': action.partnerId,
          'actionType': action.actionType.toString().split('.').last,
          'actionDescription': action.actionDescription,
          'actionTimestamp': action.actionTimestamp,
          'updatedAt': action.updatedAt,
          'isActive': action.isActive,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания действия');
      }
      return OrderActions.fromJson(result);
    } catch (e) {
      print('Ошибка создания действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> update(OrderActions action) async {
    try {
      final result = await queryOne(
        '''
        UPDATE order_actions 
        SET 
          action_type = @actionType::action_type,
          action_description = @actionDescription,
          action_timestamp = @actionTimestamp,
          updated_at = @updatedAt,
          is_active = @isActive
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': action.id,
          'actionType': action.actionType.toString().split('.').last,
          'actionDescription': action.actionDescription,
          'actionTimestamp': action.actionTimestamp,
          'updatedAt': action.updatedAt,
          'isActive': action.isActive,
        },
      );
      if (result == null) {
        throw Exception('Действие не найдено');
      }
      return OrderActions.fromJson(result);
    } catch (e) {
      print('Ошибка обновления действия: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getByActionType(ActionType actionType) async {
    try {
      final results = await query(
        'SELECT * FROM order_actions WHERE action_type = @actionType::action_type',
        params: {'actionType': actionType.toString().split('.').last},
      );
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения действий по типу: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getActiveActions() async {
    try {
      final results = await query(
        'SELECT * FROM order_actions WHERE is_active = true',
      );
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения активных действий: $e');
      rethrow;
    }
  }
} 