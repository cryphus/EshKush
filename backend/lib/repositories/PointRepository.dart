import 'package:postgres/postgres.dart';
import '../model/entities/Point.dart';
import '../model/entities/PointCategory.dart';
import '../model/entities/PointCategoryMap.dart';

class PointRepository {
  final PostgreSQLConnection _connection;

  PointRepository(this._connection);

  Future<List<Point>> findAll() async {
    final results = await _connection.mappedResultsQuery('SELECT * FROM points');
    return results.map((row) => Point.fromJson(row['points']!)).toList();
  }

  Future<Point?> findById(int id) async {
    try {
      final result = await _connection.mappedResultsQuery(
        'SELECT * FROM points WHERE id = @id',
        substitutionValues: {'id': id},
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Point.fromJson(result.first['points']!);
    } catch (e) {
      print('Ошибка поиска точки по ID: $e');
      rethrow;
    }
  }

  Future<List<Point>> findByCategory(int categoryId) async {
    try {
      final results = await _connection.mappedResultsQuery('''
        SELECT p.* FROM points p
        JOIN point_category_map pcm ON p.id = pcm.point_id
        WHERE pcm.category_id = @categoryId
      ''', substitutionValues: {'categoryId': categoryId});
      
      return results.map((row) => Point.fromJson(row['points']!)).toList();
    } catch (e) {
      print('Ошибка поиска точек по категории: $e');
      rethrow;
    }
  }

  Future<List<PointCategory>> getCategoriesForPoint(int pointId) async {
    try {
      final results = await _connection.mappedResultsQuery('''
        SELECT c.* FROM point_categories c
        JOIN point_category_map pcm ON c.id = pcm.category_id
        WHERE pcm.point_id = @pointId
      ''', substitutionValues: {'pointId': pointId});
      
      return results.map((row) => PointCategory.fromJson(row['point_categories']!)).toList();
    } catch (e) {
      print('Ошибка получения категорий для точки: $e');
      rethrow;
    }
  }

  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      final result = await _connection.mappedResultsQuery('''
        INSERT INTO points (
          name, address, city_id, products, opening_hours, 
          closing_hours, partner_id, longitude, latitude, tags
        ) VALUES (
          @name, @address, @city_id, @products, @opening_hours,
          @closing_hours, @partner_id, @longitude, @latitude, @tags
        ) RETURNING *
      ''', substitutionValues: {
        'name': data['name'],
        'address': data['address'],
        'city_id': data['city_id'],
        'products': data['products'] ?? {},
        'opening_hours': data['opening_hours'],
        'closing_hours': data['closing_hours'],
        'partner_id': data['partner_id'],
        'longitude': data['longitude'],
        'latitude': data['latitude'],
        'tags': data['tags'] ?? {},
      });
      
      return Point.fromJson(result.first['points']!);
    } catch (e) {
      print('Ошибка создания точки: $e');
      rethrow;
    }
  }

  Future<Point?> updatePoint(int id, Map<String, dynamic> data) async {
    try {
      final setClause = data.keys
          .map((key) => '$key = @$key')
          .join(', ');
      
      final result = await _connection.mappedResultsQuery(
        '''
        UPDATE points 
        SET $setClause, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        substitutionValues: {
          'id': id,
          ...data,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Point.fromJson(result.first['points']!);
    } catch (e) {
      print('Ошибка обновления точки: $e');
      rethrow;
    }
  }

  Future<Point?> deletePoint(int id) async {
    try {
      final result = await _connection.mappedResultsQuery(
        'DELETE FROM points WHERE id = @id RETURNING *',
        substitutionValues: {'id': id},
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Point.fromJson(result.first['points']!);
    } catch (e) {
      print('Ошибка удаления точки: $e');
      rethrow;
    }
  }

  Future<Point?> updateRating(int pointId, double rating) async {
    try {
      final result = await _connection.mappedResultsQuery(
        '''
        UPDATE points 
        SET rating = @rating, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        substitutionValues: {
          'id': pointId,
          'rating': rating,
        },
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Point.fromJson(result.first['points']!);
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
      rethrow;
    }
  }

  Future<void> updatePointCategories(int pointId, List<int> categoryIds) async {
    // Начинаем транзакцию
    await _connection.transaction((txn) async {
      // Удаляем все существующие маппинги
      await txn.mappedResultsQuery(
        'DELETE FROM point_category_map WHERE point_id = @pointId',
        substitutionValues: {'pointId': pointId},
      );

      // Создаем новые маппинги
      for (final categoryId in categoryIds) {
        await txn.mappedResultsQuery('''
          INSERT INTO point_category_map (point_id, category_id, created_at)
          VALUES (@pointId, @categoryId, @createdAt)
        ''', substitutionValues: {
          'pointId': pointId,
          'categoryId': categoryId,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    });
  }
} 