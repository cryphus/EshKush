import 'package:postgres/postgres.dart';
import '../model/entities/Point.dart';

class PointRepository {
  final PostgreSQLConnection _connection;

  PointRepository(this._connection);

  Future<Point?> findById(int id) async {
    try {
      final results = await _connection.mappedResultsQuery(
        'SELECT * FROM points WHERE id = @id',
        substitutionValues: {'id': id},
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      return Point.fromJson(results.first['points']!);
    } catch (e) {
      print('Ошибка поиска точки по ID: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(
        query,
        substitutionValues: params,
      );
      
      return results.map((row) => row['points']!).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      final results = await _connection.mappedResultsQuery(
        '''
        INSERT INTO points (
          name, address, city_id, products, opening_hours, 
          closing_hours, partner_id, longitude, latitude, tags
        ) VALUES (
          @name, @address, @city_id, @products, @opening_hours,
          @closing_hours, @partner_id, @longitude, @latitude, @tags
        ) RETURNING *
        ''',
        substitutionValues: {
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
        },
      );
      
      return Point.fromJson(results.first['points']!);
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
      
      final results = await _connection.mappedResultsQuery(
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
      
      if (results.isEmpty) {
        return null;
      }
      
      return Point.fromJson(results.first['points']!);
    } catch (e) {
      print('Ошибка обновления точки: $e');
      rethrow;
    }
  }

  Future<Point?> deletePoint(int id) async {
    try {
      final results = await _connection.mappedResultsQuery(
        'DELETE FROM points WHERE id = @id RETURNING *',
        substitutionValues: {'id': id},
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      return Point.fromJson(results.first['points']!);
    } catch (e) {
      print('Ошибка удаления точки: $e');
      rethrow;
    }
  }

  Future<Point?> updateRating(int pointId, double rating) async {
    try {
      final results = await _connection.mappedResultsQuery(
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
      
      if (results.isEmpty) {
        return null;
      }
      
      return Point.fromJson(results.first['points']!);
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
      rethrow;
    }
  }
} 