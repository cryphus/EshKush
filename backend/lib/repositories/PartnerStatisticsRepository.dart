import 'package:postgres/postgres.dart';
import '../model/entities/PartnerStatistics.dart';

class PartnerStatisticsRepository {
  final PostgreSQLConnection _connection;

  PartnerStatisticsRepository(this._connection);

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

  Future<PartnerStatistics?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM partner_statistics WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : PartnerStatistics.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerStatistics?> findByPartnerId(int partnerId) async {
    try {
      final result = await queryOne(
        'SELECT * FROM partner_statistics WHERE partner_id = @partnerId',
        params: {'partnerId': partnerId},
      );
      return result == null ? null : PartnerStatistics.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerStatistics?> findByPointId(int pointId) async {
    try {
      final result = await queryOne(
        'SELECT * FROM partner_statistics WHERE point_id = @pointId',
        params: {'pointId': pointId},
      );
      return result == null ? null : PartnerStatistics.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerStatistics> create(PartnerStatistics statistics) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO partner_statistics (
          partner_id, point_id, total_orders, total_revenue,
          total_cancel, average_rating, total_reviews, created_at
        )
        VALUES (
          @partnerId, @pointId, @totalOrders, @totalRevenue,
          @totalCancel, @averageRating, @totalReviews, @createdAt
        )
        RETURNING *
        ''',
        params: {
          'partnerId': statistics.partnerId,
          'pointId': statistics.pointId,
          'totalOrders': statistics.totalOrders,
          'totalRevenue': statistics.totalRevenue,
          'totalCancel': statistics.totalCancel,
          'averageRating': statistics.averageRating,
          'totalReviews': statistics.totalReviews,
          'createdAt': statistics.createdAt,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания статистики');
      }
      return PartnerStatistics.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerStatistics> update(PartnerStatistics statistics) async {
    try {
      final result = await queryOne(
        '''
        UPDATE partner_statistics 
        SET 
          total_orders = @totalOrders,
          total_revenue = @totalRevenue,
          total_cancel = @totalCancel,
          average_rating = @averageRating,
          total_reviews = @totalReviews,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': statistics.id,
          'totalOrders': statistics.totalOrders,
          'totalRevenue': statistics.totalRevenue,
          'totalCancel': statistics.totalCancel,
          'averageRating': statistics.averageRating,
          'totalReviews': statistics.totalReviews,
        },
      );
      if (result == null) {
        throw Exception('Статистика не найдена');
      }
      return PartnerStatistics.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deactivate(int id) async {
    try {
      await queryOne(
        '''
        UPDATE partner_statistics 
        SET is_active = false, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        ''',
        params: {'id': id},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> activate(int id) async {
    try {
      await queryOne(
        '''
        UPDATE partner_statistics 
        SET is_active = true, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        ''',
        params: {'id': id},
      );
    } catch (e) {
      rethrow;
    }
  }
} 