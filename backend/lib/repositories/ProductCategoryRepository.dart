import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/ProductCategory.dart';
import '../utils/AppException.dart';

class ProductCategoryRepository extends BaseRepository {
  ProductCategoryRepository(PostgreSQLConnection connection)
      : super(connection);

  Future<ProductCategory?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM product_categories WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : ProductCategory.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductCategory>> findAll() async {
    try {
      final results = await query('SELECT * FROM product_categories');
      return results.map((map) => ProductCategory.fromJson(map)).toList();
    } catch (e) {
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
        throw const InternalServerException();
      }
      return ProductCategory.fromJson(result);
    } catch (e) {
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
        throw const NotFoundException(
            'Р С™Р В°РЎвЂљР ВµР С–Р С•РЎР‚Р С‘РЎРЏ Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°');
      }
      return ProductCategory.fromJson(result);
    } catch (e) {
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
        throw const NotFoundException(
            'Р С™Р В°РЎвЂљР ВµР С–Р С•РЎР‚Р С‘РЎРЏ Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°');
      }
    } catch (e) {
      rethrow;
    }
  }
}
