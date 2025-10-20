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
      return results.map((row) {
        final merged = <String, dynamic>{};
        for (final part in row.values) {
          merged.addAll(part);
        }
        return merged;
      }).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> queryOne(String sql, {Map<String, dynamic>? params}) async {
    try {
      final results = await connection.mappedResultsQuery(sql, substitutionValues: params);
      if (results.isEmpty) return null;
      final row = results.first;
      final merged = <String, dynamic>{};
      for (final part in row.values) {
        merged.addAll(part);
      }
      return merged;
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