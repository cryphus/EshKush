import 'package:postgres/postgres.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/SafeLoggingUtils.dart';
import '../model/enums/ActionType.dart';

class OrderRepository {
  final PostgreSQLConnection _connection;
  PostgreSQLConnection? _transactionConnection;

  OrderRepository(this._connection);

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
      print('Ошибка поиска заказа по ID: $e');
      rethrow;
    }
  }

  Future<Order> createOrder(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('Создание заказа с данными', data);
      
      // Преобразуем числовые значения
      final userId = data['user_id'] is String ? int.parse(data['user_id']) : (data['user_id'] as num).toInt();
      final pointId = data['point_id'] is String ? int.parse(data['point_id']) : (data['point_id'] as num).toInt();
      final totalPrice = data['total_price'] is String ? double.parse(data['total_price']) : (data['total_price'] as num).toDouble();
      
      // Преобразуем массив products_id
      final productsId = (data['products_id'] as List).map((e) {
        if (e is String) return int.parse(e);
        return e as int;
      }).toList();
      
      print('Преобразованные значения:');
      print('userId: $userId');
      print('pointId: $pointId');
      print('totalPrice: $totalPrice');
      print('productsId: $productsId');
      
      final result = await _connection.mappedResultsQuery(
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
      
      if (result.isEmpty) {
        throw Exception('Ошибка создания заказа');
      }
      
      print('Результат из БД: ${result.first.values.first}');
      return Order.fromJson(result.first.values.first);
    } catch (e) {
      print('Ошибка создания заказа: $e');
      rethrow;
    }
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
      print('Ошибка обновления статуса заказа: $e');
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
      print('Ошибка удаления заказа: $e');
      rethrow;
    }
  }

  Future<void> beginTransaction() async {
    await _connection.execute('BEGIN');
  }

  Future<void> commitTransaction() async {
    await _connection.execute('COMMIT');
  }

  Future<void> rollbackTransaction() async {
    await _connection.execute('ROLLBACK');
  }

  Future<void> createOrderHistory({
    required int orderId,
    required int pointId,
    required int userId,
    required DateTime orderDate,
    required double totalSum,
    required OrderStatus status,
  }) async {
    final connection = _transactionConnection ?? _connection;
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
    final connection = _transactionConnection ?? _connection;
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
      final where = status != null ? 'WHERE status = @status::order_status' : '';
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

      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => Order.fromJson(row.values.first)).toList();
    } catch (e) {
      print('Ошибка получения списка заказов: $e');
      rethrow;
    }
  }
} 