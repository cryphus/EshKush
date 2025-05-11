import 'package:postgres/postgres.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';

class OrderRepository {
  final PostgreSQLConnection _connection;

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
        'SELECT * FROM orders WHERE id = @id',
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
      final result = await queryOne(
        '''
        INSERT INTO orders (user_id, point_id, date, status, total_price)
        VALUES (@user_id, @point_id, @date, @status::order_status, @total_price)
        RETURNING *
        ''',
        params: {
          'user_id': data['user_id'],
          'point_id': data['point_id'],
          'date': DateTime.now(),
          'status': OrderStatus.pending.name.toLowerCase(),
          'total_price': data['total_price'],
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания заказа');
      }

      // Создаем записи в order_items
      for (var productId in data['products_id']) {
        await queryOne(
          '''
          INSERT INTO order_items (order_id, product_id, quantity, price)
          VALUES (@order_id, @product_id, @quantity, @price)
          ''',
          params: {
            'order_id': result['id'],
            'product_id': productId,
            'quantity': 1, // TODO: Добавить количество в data
            'price': data['total_price'] / (data['products_id'] as List).length,
          },
        );
      }

      return Order.fromJson(result);
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
        SET status = @status::order_status
        WHERE id = @id
        RETURNING *
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
        'DELETE FROM orders WHERE id = @id RETURNING *',
        params: {'id': id},
      );
      return result == null ? null : Order.fromJson(result);
    } catch (e) {
      print('Ошибка удаления заказа: $e');
      rethrow;
    }
  }
} 