import 'package:postgres/postgres.dart';

abstract class BaseRepository {
  final PostgreSQLConnection connection;
  
  BaseRepository(this.connection);
  
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) async {
    final results = await connection.mappedResultsQuery(
      sql,
      substitutionValues: params,
    );
    return results.map((row) => row.values.first).toList();
  }
  
  Future<Map<String, dynamic>?> queryOne(String sql, {Map<String, dynamic>? params}) async {
    final results = await query(sql, params: params);
    return results.isEmpty ? null : results.first;
    
  }
} 