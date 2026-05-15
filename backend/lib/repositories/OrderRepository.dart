import 'package:postgres/postgres.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/SafeLoggingUtils.dart';
import '../model/enums/ActionType.dart';
import 'BaseRepository.dart';
import '../utils/AppException.dart';

class OrderRepository extends BaseRepository {
  OrderRepository(PostgreSQLConnection connection) : super(connection);

  Future<Order?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          user_id,
          point_id,
          products_id,
          to_char(date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as date,
          status,
          total_price,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM orders 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : Order.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  /// Р РЋР С•Р В·Р Т‘Р В°РЎвЂРЎвЂљ Р В·Р В°Р С”Р В°Р В· Р С‘ РЎРѓР Р†РЎРЏР В·Р В°Р Р…Р Р…РЎС“РЎР‹ Р В·Р В°Р С—Р С‘РЎРѓРЎРЉ Р С• Р С—Р В»Р В°РЎвЂљР ВµР В¶Р Вµ Р В°РЎвЂљР С•Р СР В°РЎР‚Р Р…Р С• Р Р† Р С•Р Т‘Р Р…Р С•Р в„– DB-РЎвЂљРЎР‚Р В°Р Р…Р В·Р В°Р С”РЎвЂ Р С‘Р С‘.
  Future<Order> createWithPayment(Map<String, dynamic> data) async {
    SafeLoggingUtils.logData(
        'Р РЋР С•Р В·Р Т‘Р В°Р Р…Р С‘Р Вµ Р В·Р В°Р С”Р В°Р В·Р В° РЎРѓ Р Т‘Р В°Р Р…Р Р…РЎвЂ№Р СР С‘',
        data);

    final userId = data['user_id'] is String
        ? int.parse(data['user_id'])
        : (data['user_id'] as num).toInt();
    final pointId = data['point_id'] is String
        ? int.parse(data['point_id'])
        : (data['point_id'] as num).toInt();
    final totalPrice = data['total_price'] is String
        ? double.parse(data['total_price'])
        : (data['total_price'] as num).toDouble();
    final productsId = (data['products_id'] as List).map((e) {
      if (e is String) return int.parse(e);
      return e as int;
    }).toList();

    late Order order;
    await transaction((txn) async {
      final orderResult = await txn.mappedResultsQuery(
        '''
        WITH inserted_order AS (
          INSERT INTO orders (
            user_id, point_id, products_id, date, total_price, status, created_at
          ) VALUES (
            @user_id, @point_id, @products_id, @date, @total_price, 'pending', CURRENT_TIMESTAMP
          ) RETURNING *
        )
        SELECT
          id,
          products_id,
          user_id,
          point_id,
          to_char(date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as date,
          status,
          total_price,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM inserted_order
        ''',
        substitutionValues: {
          'user_id': userId,
          'point_id': pointId,
          'products_id': productsId,
          'date': data['date'],
          'total_price': totalPrice,
        },
      );

      if (orderResult.isEmpty) throw const InternalServerException();
      order = Order.fromJson(orderResult.first.values.first);

      // Р РЋР С•Р В·Р Т‘Р В°РЎвЂР С Р В·Р В°Р С—Р С‘РЎРѓРЎРЉ Р С• Р С—Р В»Р В°РЎвЂљР ВµР В¶Р Вµ Р В°РЎвЂљР С•Р СР В°РЎР‚Р Р…Р С• Р Р†Р СР ВµРЎРѓРЎвЂљР Вµ РЎРѓ Р В·Р В°Р С”Р В°Р В·Р С•Р С.
      // provider_transaction_id = order.id Р С”Р В°Р С” placeholder Р Т‘Р С• Р С—Р С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘РЎРЏ Р С•РЎвЂљР Р†Р ВµРЎвЂљР В° Р С•РЎвЂљ Р С—Р В»Р В°РЎвЂљРЎвЂР В¶Р Р…Р С•Р С–Р С• Р С—РЎР‚Р С•Р Р†Р В°Р в„–Р Т‘Р ВµРЎР‚Р В°.
      await txn.mappedResultsQuery(
        '''
        INSERT INTO payment_transactions (
          order_id, provider_transaction_id, order_price, payment_method, status, transaction_date, is_active
        ) VALUES (
          @orderId, @orderId, @orderPrice, 'other', 'pending', CURRENT_TIMESTAMP, true
        )
        ''',
        substitutionValues: {
          'orderId': order.id,
          'orderPrice': totalPrice,
        },
      );
    });

    return order;
  }

  Future<Order?> updateStatus(int id, OrderStatus status) async {
    try {
      final result = await queryOne(
        '''
        UPDATE orders 
        SET status = @status::order_status, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING 
          id,
          user_id,
          point_id,
          products_id,
          to_char(date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as date,
          status,
          total_price,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        ''',
        params: {
          'id': id,
          'status': status.name.toLowerCase(),
        },
      );
      return result == null ? null : Order.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<Order?> deleteOrder(int id) async {
    try {
      final result = await queryOne(
        '''
        DELETE FROM orders 
        WHERE id = @id 
        RETURNING 
          id,
          user_id,
          point_id,
          products_id,
          to_char(date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as date,
          status,
          total_price,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        ''',
        params: {'id': id},
      );
      return result == null ? null : Order.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOrderHistory({
    required int orderId,
    required int pointId,
    required int userId,
    required DateTime orderDate,
    required double totalSum,
    required OrderStatus status,
  }) async {
    await connection.execute(
      '''
      INSERT INTO order_history (
        order_id, point_id, user_id, order_date, total_sum, status
      ) VALUES (
        @orderId, @pointId, @userId, @orderDate, @totalSum, @status::order_status
      )
      ''',
      substitutionValues: {
        'orderId': orderId,
        'pointId': pointId,
        'userId': userId,
        'orderDate': orderDate.toIso8601String(),
        'totalSum': totalSum,
        'status': status.name.toLowerCase(),
      },
    );
  }

  Future<void> createOrderAction({
    required int orderId,
    required int partnerId,
    required String actionDescription,
    required ActionType actionType,
  }) async {
    await connection.execute(
      '''
      INSERT INTO order_actions (
        order_id, partner_id, action_description, action_type
      ) VALUES (
        @orderId, @partnerId, @actionDescription, @actionType::action_type
      )
      ''',
      substitutionValues: {
        'orderId': orderId,
        'partnerId': partnerId,
        'actionDescription': actionDescription,
        'actionType': actionType.name.toLowerCase(),
      },
    );
  }

  Future<List<Order>> getAllOrders({
    OrderStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final where =
          status != null ? 'WHERE status = @status::order_status' : '';
      final query = '''
        SELECT
          id,
          user_id,
          point_id,
          products_id,
          to_char(date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as date,
          status,
          total_price,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM orders
        $where
        ORDER BY created_at DESC
        LIMIT @limit OFFSET @offset
      ''';

      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) params['status'] = status.name.toLowerCase();

      final results = await connection.mappedResultsQuery(query,
          substitutionValues: params);
      return results.map((row) => Order.fromJson(row.values.first)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
