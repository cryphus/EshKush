import 'package:postgres/postgres.dart';
import '../model/entities/OrderHistory.dart';
import '../model/enums/HistoryStatus.dart';

class OrderHistoryRepository {
  final PostgreSQLConnection _connection;

  OrderHistoryRepository(this._connection);

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

  Future<OrderHistory?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM order_history WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : OrderHistory.fromJson(result);
    } catch (e) {
      print('Ошибка поиска истории заказа по ID: $e');
      rethrow;
    }
  }

  Future<List<OrderHistory>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM order_history WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => OrderHistory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска истории заказов пользователя: $e');
      rethrow;
    }
  }

  Future<List<OrderHistory>> findByPointId(int pointId) async {
    try {
      final results = await query(
        'SELECT * FROM order_history WHERE point_id = @pointId',
        params: {'pointId': pointId},
      );
      return results.map((map) => OrderHistory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска истории заказов точки: $e');
      rethrow;
    }
  }

  Future<OrderHistory> create(OrderHistory orderHistory) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO order_history (
          order_id, point_id, user_id, order_date, completion_date,
          total_sum, status, receipt_link, discount_applied,
          promo_code_used, co2_saved, notes, created_at, updated_at
        )
        VALUES (
          @orderId, @pointId, @userId, @orderDate, @completionDate,
          @totalSum, @status::history_status, @receiptLink, @discountApplied,
          @promoCodeUsed, @co2Saved, @notes, @createdAt, @updatedAt
        )
        RETURNING *
        ''',
        params: {
          'orderId': orderHistory.orderId,
          'pointId': orderHistory.pointId,
          'userId': orderHistory.userId,
          'orderDate': orderHistory.orderDate,
          'completionDate': orderHistory.completionDate,
          'totalSum': orderHistory.totalSum.toString(),
          'status': orderHistory.status.toString().split('.').last,
          'receiptLink': orderHistory.receiptLink,
          'discountApplied': orderHistory.discountApplied,
          'promoCodeUsed': orderHistory.promoCodeUsed,
          'co2Saved': orderHistory.co2Saved,
          'notes': orderHistory.notes,
          'createdAt': orderHistory.createdAt,
          'updatedAt': orderHistory.updatedAt,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания истории заказа');
      }
      return OrderHistory.fromJson(result);
    } catch (e) {
      print('Ошибка создания истории заказа: $e');
      rethrow;
    }
  }

  Future<OrderHistory> update(OrderHistory orderHistory) async {
    try {
      final result = await queryOne(
        '''
        UPDATE order_history 
        SET 
          completion_date = @completionDate,
          total_sum = @totalSum,
          status = @status::history_status,
          receipt_link = @receiptLink,
          discount_applied = @discountApplied,
          promo_code_used = @promoCodeUsed,
          co2_saved = @co2Saved,
          notes = @notes,
          updated_at = @updatedAt
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': orderHistory.id,
          'completionDate': orderHistory.completionDate,
          'totalSum': orderHistory.totalSum.toString(),
          'status': orderHistory.status.toString().split('.').last,
          'receiptLink': orderHistory.receiptLink,
          'discountApplied': orderHistory.discountApplied,
          'promoCodeUsed': orderHistory.promoCodeUsed,
          'co2Saved': orderHistory.co2Saved,
          'notes': orderHistory.notes,
          'updatedAt': orderHistory.updatedAt,
        },
      );
      if (result == null) {
        throw Exception('История заказа не найдена');
      }
      return OrderHistory.fromJson(result);
    } catch (e) {
      print('Ошибка обновления истории заказа: $e');
      rethrow;
    }
  }

  Future<List<OrderHistory>> getByStatus(HistoryStatus status) async {
    try {
      final results = await query(
        'SELECT * FROM order_history WHERE status = @status::history_status',
        params: {'status': status.toString().split('.').last},
      );
      return results.map((map) => OrderHistory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения истории заказов по статусу: $e');
      rethrow;
    }
  }

  Future<List<OrderHistory>> getByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final results = await query(
        '''
        SELECT * FROM order_history 
        WHERE order_date BETWEEN @startDate AND @endDate
        ''',
        params: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return results.map((map) => OrderHistory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения истории заказов по диапазону дат: $e');
      rethrow;
    }
  }
} 