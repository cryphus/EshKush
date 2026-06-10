import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/UserFavorite.dart';
import '../utils/AppException.dart';

class UserFavoriteRepository extends BaseRepository {
  UserFavoriteRepository(PostgreSQLConnection connection) : super(connection);

  Future<List<UserFavorite>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM user_favorites WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => UserFavorite.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserFavorite>> findByPointId(int pointId) async {
    try {
      final results = await query(
        'SELECT * FROM user_favorites WHERE point_id = @pointId',
        params: {'pointId': pointId},
      );
      return results.map((map) => UserFavorite.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserFavorite> create(UserFavorite favorite) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO user_favorites (user_id, point_id, created_at)
        VALUES (@userId, @pointId, @createdAt)
        RETURNING *
        ''',
        params: {
          'userId': favorite.userId,
          'pointId': favorite.pointId,
          'createdAt': favorite.createdAt.toIso8601String(),
        },
      );
      if (result == null) {
        throw const InternalServerException();
      }
      return UserFavorite.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int userId, int pointId) async {
    try {
      final result = await queryOne(
        '''
        DELETE FROM user_favorites 
        WHERE user_id = @userId AND point_id = @pointId 
        RETURNING user_id
        ''',
        params: {
          'userId': userId,
          'pointId': pointId,
        },
      );
      if (result == null) {
        throw const NotFoundException(
            'Р СљР ВµРЎРѓРЎвЂљР С• Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р С• Р Р† Р С‘Р В·Р В±РЎР‚Р В°Р Р…Р Р…Р С•Р С');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> exists(int userId, int pointId) async {
    try {
      final result = await queryOne(
        '''
        SELECT EXISTS(
          SELECT 1 FROM user_favorites 
          WHERE user_id = @userId AND point_id = @pointId
        ) as exists
        ''',
        params: {
          'userId': userId,
          'pointId': pointId,
        },
      );
      return result?['exists'] as bool? ?? false;
    } catch (e) {
      rethrow;
    }
  }
}
