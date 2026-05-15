import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/OrderActions.dart';
import '../model/enums/ActionType.dart';

class OrderActionsRepository extends BaseRepository {
  final PostgreSQLConnection _connection;

  OrderActionsRepository(this._connection) : super(_connection);

  Future<OrderActions?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM order_actions WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : OrderActions.fromJson(result);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<List<OrderActions>> findByPartnerId(int partnerId) async {
    try {
      final results = await query(
        '''
        SELECT oa.*
        FROM order_actions oa
        JOIN orders o ON oa.order_id = o.id
        JOIN points p ON o.point_id = p.id
        WHERE p.partner_id = @partnerId
        ''',
        params: {'partnerId': partnerId},
      );
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderActions> create(OrderActions action) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO order_actions (
          order_id, action_type, description
        )
        VALUES (
          @orderId, @actionType::action_type, @description
        )
        RETURNING *
        ''',
        params: {
          'orderId': action.orderId,
          'actionType': action.actionType.toString().split('.').last,
          'description': action.description,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания действия');
      }
      return OrderActions.fromJson(result);
    } catch (e) {
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
          description = @description
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': action.id,
          'actionType': action.actionType.toString().split('.').last,
          'description': action.description,
        },
      );
      if (result == null) {
        throw Exception('Действие не найдено');
      }
      return OrderActions.fromJson(result);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<List<OrderActions>> getActiveActions() async {
    try {
      final results = await query('SELECT * FROM order_actions');
      return results.map((map) => OrderActions.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
