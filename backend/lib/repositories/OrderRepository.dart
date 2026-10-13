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

  /// Создаёт заказ и связанную запись о платеже атомарно в одной DB-транзакции.
  Future<Order> createWithPayment(Map<String, dynamic> data) async {
    SafeLoggingUtils.logData(
        'Создание заказа с данными',
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

      // Списываем остаток атомарно в той же транзакции: UPDATE ... WHERE
      // quantity >= @qty гарантирует, что при гонке двух заказов на
      // последний товар только один из них спишет остаток успешно —
      // второй получит 0 обновлённых строк и упадёт в ConflictException,
      // откатывая всю транзакцию (заказ и платёж не создадутся).
      final requestedQty = <int, int>{};
      for (final id in productsId) {
        requestedQty[id] = (requestedQty[id] ?? 0) + 1;
      }
      for (final entry in requestedQty.entries) {
        final updated = await txn.query(
          '''
          UPDATE products
          SET quantity = quantity - @qty
          WHERE id = @productId AND quantity >= @qty
          RETURNING quantity
          ''',
          substitutionValues: {'productId': entry.key, 'qty': entry.value},
        );
        if (updated.isEmpty) {
          throw ConflictException(
            'Недостаточно товара на складе (id: ${entry.key})',
          );
        }
      }

      // Создаём запись о платеже атомарно вместе с заказом.
      // provider_transaction_id = order.id как placeholder до получения ответа от платёжного провайдера.
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
    Order? result;
    await transaction((txn) async {
      final rows = await txn.mappedResultsQuery(
        'SELECT * FROM orders WHERE id=@id FOR UPDATE', substitutionValues: {'id': id});
      if (rows.isEmpty) return;
      final current = Order.fromJson(rows.first.values.first);
      if (current.status == OrderStatus.cancelled && status != OrderStatus.cancelled) {
        throw const ConflictException('Отменённый заказ нельзя восстановить');
      }
      if (status == OrderStatus.processing || status == OrderStatus.completed) {
        final paid = await txn.query("SELECT id FROM payment_transactions WHERE order_id=@id AND status='completed' AND is_active=true LIMIT 1",
          substitutionValues: {'id': id});
        if (paid.isEmpty) throw const ConflictException('Сначала оплатите заказ');
      }
      if (status == OrderStatus.cancelled && current.status != OrderStatus.cancelled && current.status != OrderStatus.completed) {
        final quantities = <int, int>{};
        for (final product in current.productsId) { quantities[product] = (quantities[product] ?? 0) + 1; }
        for (final entry in quantities.entries) {
          await txn.execute('UPDATE products SET quantity=quantity+@qty WHERE id=@product',
            substitutionValues: {'qty': entry.value, 'product': entry.key});
        }
      }
      final updated = await txn.mappedResultsQuery(
        'UPDATE orders SET status=@status::order_status, updated_at=CURRENT_TIMESTAMP WHERE id=@id RETURNING *',
        substitutionValues: {'status': status.name, 'id': id});
      result = Order.fromJson(updated.first.values.first);
    });
    return result;
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
    required String description,
    required ActionType actionType,
  }) async {
    await connection.execute(
      '''
      INSERT INTO order_actions (
        order_id, action_type, description
      ) VALUES (
        @orderId, @actionType::action_type, @description
      )
      ''',
      substitutionValues: {
        'orderId': orderId,
        'actionType': actionType.name.toLowerCase(),
        'description': description,
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
