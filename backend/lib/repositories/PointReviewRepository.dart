import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/PointReview.dart';
import '../utils/AppException.dart';

class PointReviewRepository extends BaseRepository {
  PointReviewRepository(PostgreSQLConnection connection) : super(connection);

  Future<PointReview?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT
          pr.id,
          pr.point_id,
          pr.user_id,
          u.username,
          pr.rating,
          pr.comment,
          to_char(pr.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM point_reviews pr
        LEFT JOIN users u ON u.id = pr.user_id
        WHERE pr.id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : PointReview.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointReview>> findByPointId(int pointId) async {
    try {
      final results = await query(
        '''
        SELECT
          pr.id,
          pr.point_id,
          pr.user_id,
          u.username,
          pr.rating,
          pr.comment,
          to_char(pr.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM point_reviews pr
        LEFT JOIN users u ON u.id = pr.user_id
        WHERE pr.point_id = @point_id
        ORDER BY pr.created_at DESC
        ''',
        params: {'point_id': pointId},
      );
      return results.map((map) => PointReview.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointReview>> findByUserId(int userId) async {
    try {
      final results = await query(
        '''
        SELECT
          pr.id,
          pr.point_id,
          pr.user_id,
          u.username,
          pr.rating,
          pr.comment,
          to_char(pr.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM point_reviews pr
        LEFT JOIN users u ON u.id = pr.user_id
        WHERE pr.user_id = @user_id
        ORDER BY pr.created_at DESC
        ''',
        params: {'user_id': userId},
      );
      return results.map((map) => PointReview.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PointReview> create(PointReview review) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO point_reviews (point_id, user_id, rating, comment, created_at)
        VALUES (@point_id, @user_id, @rating, @comment, CURRENT_TIMESTAMP)
        RETURNING 
          id,
          point_id,
          user_id,
          rating,
          comment,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        ''',
        params: {
          'point_id': review.pointId,
          'user_id': review.userId,
          'rating': review.rating,
          'comment': review.comment,
        },
      );
      if (result == null) {
        throw const InternalServerException();
      }
      return PointReview.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PointReview> update(PointReview review) async {
    try {
      final result = await queryOne(
        '''
        UPDATE point_reviews 
        SET point_id = @point_id, user_id = @user_id, rating = @rating, comment = @comment
        WHERE id = @id
        RETURNING 
          id,
          point_id,
          user_id,
          rating,
          comment,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        ''',
        params: {
          'id': review.id,
          'point_id': review.pointId,
          'user_id': review.userId,
          'rating': review.rating,
          'comment': review.comment,
        },
      );
      if (result == null) {
        throw const NotFoundException();
      }
      return PointReview.fromJson(result);
    } catch (e) {
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
        throw const NotFoundException();
      }
    } catch (e) {
      rethrow;
    }
  }
}
