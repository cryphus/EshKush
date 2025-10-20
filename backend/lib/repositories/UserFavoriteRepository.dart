import 'package:postgres/postgres.dart';
import '../model/entities/UserFavorite.dart';

class UserFavoriteRepository {
  final PostgreSQLConnection _connection;

  UserFavoriteRepository(this._connection);

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

  Future<List<UserFavorite>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM user_favorites WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => UserFavorite.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска избранных мест пользователя: $e');
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
      print('Ошибка поиска пользователей, добавивших место в избранное: $e');
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
        throw Exception('Ошибка добавления места в избранное');
      }
      return UserFavorite.fromJson(result);
    } catch (e) {
      print('Ошибка добавления места в избранное: $e');
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
        throw Exception('Место не найдено в избранном');
      }
    } catch (e) {
      print('Ошибка удаления места из избранного: $e');
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
      print('Ошибка проверки существования места в избранном: $e');
      rethrow;
    }
  }
} 