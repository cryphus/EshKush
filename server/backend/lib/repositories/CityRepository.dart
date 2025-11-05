import 'package:postgres/postgres.dart';
import '../model/entities/City.dart';
import '../utils/SafeLoggingUtils.dart';

class CityRepository {
  final PostgreSQLConnection _connection;

  CityRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      if (results.isEmpty) return null;
      final map = results.first.values.first;
      // Преобразуем DateTime в строку
      if (map['created_at'] is DateTime) {
        map['created_at'] = (map['created_at'] as DateTime).toIso8601String();
      }
      return map;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) {
        final map = row.values.first;
        // Преобразуем DateTime в строку
        if (map['created_at'] is DateTime) {
          map['created_at'] = (map['created_at'] as DateTime).toIso8601String();
        }
        return map;
      }).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<City?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id, 
          name, 
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at 
        FROM cities 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      print('Результат поиска города по ID: $result');
      return result == null ? null : City.fromJson(result);
    } catch (e) {
      print('Ошибка поиска города по ID: $e');
      rethrow;
    }
  }

  Future<List<City>> findAll() async {
    try {
      print('Получение всех городов');
      final results = await query('''
        SELECT 
          id, 
          name, 
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at 
        FROM cities 
        ORDER BY name
      ''');
      print('Результаты запроса: $results');
      return results.map((map) => City.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения всех городов: $e');
      rethrow;
    }
  }

  Future<City> create(City city) async {
    try {
      print('Создание города: ${city.name}');
      final result = await queryOne(
        '''
        INSERT INTO cities (name)
        VALUES (@name)
        RETURNING 
          id, 
          name, 
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        ''',
        params: {
          'name': city.name,
        },
      );
      
      if (result == null) {
        throw Exception('Ошибка создания города: результат запроса пустой');
      }
      
      final safeResult = SafeLoggingUtils.sanitizeData(result);
      print('Результат создания города: $safeResult');
      return City.fromJson(result);
    } catch (e, stackTrace) {
      print('Ошибка создания города: $e');
      print('Stack trace: $stackTrace');
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
        RETURNING 
          id, 
          name, 
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
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