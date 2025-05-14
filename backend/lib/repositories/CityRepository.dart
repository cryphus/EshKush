import 'package:postgres/postgres.dart';
import '../model/entities/City.dart';

class CityRepository {
  final PostgreSQLConnection _connection;

  CityRepository(this._connection);

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

  Future<City?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM cities WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : City.fromJson(result);
    } catch (e) {
      print('Ошибка поиска города по ID: $e');
      rethrow;
    }
  }

  Future<List<City>> findAll() async {
    try {
      final results = await query('SELECT * FROM cities ORDER BY name');
      return results.map((map) => City.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения всех городов: $e');
      rethrow;
    }
  }

  Future<City> create(City city) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO cities (name)
        VALUES (@name)
        RETURNING *
        ''',
        params: {
          'name': city.name,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания города');
      }
      return City.fromJson(result);
    } catch (e) {
      print('Ошибка создания города: $e');
      rethrow;
    }
  }

  Future<City> update(City city) async {
    try {
      final result = await queryOne(
        '''
        UPDATE cities 
        SET name = @name
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': city.id,
          'name': city.name,
        },
      );
      if (result == null) {
        throw Exception('Город не найден');
      }
      return City.fromJson(result);
    } catch (e) {
      print('Ошибка обновления города: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM cities WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Город не найден');
      }
    } catch (e) {
      print('Ошибка удаления города: $e');
      rethrow;
    }
  }
} 