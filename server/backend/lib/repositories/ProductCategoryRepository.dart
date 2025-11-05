import 'package:postgres/postgres.dart';
import '../model/entities/ProductCategory.dart';

class ProductCategoryRepository {
  final PostgreSQLConnection _connection;

  ProductCategoryRepository(this._connection);

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

  Future<ProductCategory?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM product_categories WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : ProductCategory.fromJson(result);
    } catch (e) {
      print('Ошибка поиска категории по ID: $e');
      rethrow;
    }
  }

  Future<List<ProductCategory>> findAll() async {
    try {
      final results = await query('SELECT * FROM product_categories');
      return results.map((map) => ProductCategory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения всех категорий: $e');
      rethrow;
    }
  }

  Future<ProductCategory> create(ProductCategory category) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO product_categories (name, description, created_at)
        VALUES (@name, @description, @created_at)
        RETURNING *
        ''',
        params: {
          'name': category.name,
          'description': category.description,
          'created_at': category.createdAt.toIso8601String(),
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания категории');
      }
      return ProductCategory.fromJson(result);
    } catch (e) {
      print('Ошибка создания категории: $e');
      rethrow;
    }
  }

  Future<ProductCategory> update(ProductCategory category) async {
    try {
      final result = await queryOne(
        '''
        UPDATE product_categories 
        SET name = @name, description = @description
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': category.id,
          'name': category.name,
          'description': category.description,
        },
      );
      if (result == null) {
        throw Exception('Категория не найдена');
      }
      return ProductCategory.fromJson(result);
    } catch (e) {
      print('Ошибка обновления категории: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM product_categories WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Категория не найдена');
      }
    } catch (e) {
      print('Ошибка удаления категории: $e');
      rethrow;
    }
  }
} 