import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/OrderHistory.dart';
import '../model/enums/HistoryStatus.dart';
import '../utils/AppException.dart';

class OrderHistoryRepository extends BaseRepository {
  OrderHistoryRepository(PostgreSQLConnection connection) : super(connection);

  Future<OrderHistory?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM order_history WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : OrderHistory.fromJson(result);
    } catch (e) {
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
        throw const InternalServerException();
      }
      return OrderHistory.fromJson(result);
    } catch (e) {
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
        throw const NotFoundException(
            'Р ВРЎРѓРЎвЂљР С•РЎР‚Р С‘РЎРЏ Р В·Р В°Р С”Р В°Р В·Р В° Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°');
      }
      return OrderHistory.fromJson(result);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<List<OrderHistory>> getByDateRange(
      DateTime startDate, DateTime endDate) async {
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
      rethrow;
    }
  }
}
