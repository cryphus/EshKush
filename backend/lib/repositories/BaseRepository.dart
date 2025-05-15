import 'package:postgres/postgres.dart';

abstract class BaseRepository {
  final PostgreSQLConnection connection;
  
  BaseRepository(this.connection);
  
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) async {
    try {
      final results = await connection.mappedResultsQuery(
        sql,
        substitutionValues: params,
      );
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> queryOne(String sql, {Map<String, dynamic>? params}) async {
    try {
      final results = await connection.mappedResultsQuery(sql, substitutionValues: params);
      if (results.isEmpty) return null;
      return results.first.values.first;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<T> transaction<T>(Future<T> Function(PostgreSQLExecutionContext) callback) async {
    await connection.transaction((txn) async {
      await callback(txn);
    });
    return callback(connection);
  }
} 