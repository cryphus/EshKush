import 'package:postgres/postgres.dart';
import '../model/entities/PointReview.dart';

class PointReviewRepository {
  final PostgreSQLConnection _connection;

  PointReviewRepository(this._connection);

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

  Future<PointReview?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM point_reviews WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : PointReview.fromJson(result);
    } catch (e) {
      print('Ошибка поиска отзыва по ID: $e');
      rethrow;
    }
  }

  Future<List<PointReview>> findByPointId(int pointId) async {
    try {
      final results = await query(
        'SELECT * FROM point_reviews WHERE point_id = @pointId',
        params: {'pointId': pointId},
      );
      return results.map((map) => PointReview.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска отзывов по ID точки: $e');
      rethrow;
    }
  }

  Future<List<PointReview>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM point_reviews WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => PointReview.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска отзывов по ID пользователя: $e');
      rethrow;
    }
  }

  Future<PointReview> create(PointReview review) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO point_reviews (point_id, user_id, rating, comment, review_date)
        VALUES (@pointId, @userId, @rating, @comment, @reviewDate)
        RETURNING *
        ''',
        params: {
          'pointId': review.pointId,
          'userId': review.userId,
          'rating': review.rating,
          'comment': review.comment,
          'reviewDate': review.reviewDate.toIso8601String(),
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания отзыва');
      }
      return PointReview.fromJson(result);
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      rethrow;
    }
  }

  Future<PointReview> update(PointReview review) async {
    try {
      final result = await queryOne(
        '''
        UPDATE point_reviews 
        SET rating = @rating, comment = @comment
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': review.id,
          'rating': review.rating,
          'comment': review.comment,
        },
      );
      if (result == null) {
        throw Exception('Отзыв не найден');
      }
      return PointReview.fromJson(result);
    } catch (e) {
      print('Ошибка обновления отзыва: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM point_reviews WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Отзыв не найден');
      }
    } catch (e) {
      print('Ошибка удаления отзыва: $e');
      rethrow;
    }
  }
} 