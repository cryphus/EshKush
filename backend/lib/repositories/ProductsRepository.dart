import 'package:postgres/postgres.dart';
import '../model/entities/Products.dart';
import '../model/entities/ProductCategory.dart';
import 'BaseRepository.dart';

class ProductsRepository extends BaseRepository {
  ProductsRepository(super.connection);

  Future<Products?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM products WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : Products.fromJson(result);
    } catch (e) {
      print('Ошибка поиска продукта: $e');
      rethrow;
    }
  }

  Future<List<Products>> findAll() async {
    final results = await query('SELECT * FROM products');
    return results.map((map) => Products.fromJson(map)).toList();
  }

  Future<List<Products>> findByCategory(int categoryId) async {
    try {
      final results = await query('''
        SELECT p.* FROM products p
        JOIN product_category_map pcm ON p.id = pcm.product_id
        WHERE pcm.category_id = @categoryId
      ''', params: {'categoryId': categoryId});
      return results.map((map) => Products.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка поиска продуктов по категории: $e');
      rethrow;
    }
  }

  Future<List<ProductCategory>> getCategoriesForProduct(int productId) async {
    try {
      final results = await query('''
        SELECT c.* FROM product_categories c
        JOIN product_category_map pcm ON c.id = pcm.category_id
        WHERE pcm.product_id = @productId
      ''', params: {'productId': productId});
      return results.map((map) => ProductCategory.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения категорий для продукта: $e');
      rethrow;
    }
  }

  Future<Products> create(Products product) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO products (
          name, description, price, image_url, partner_id, created_at
        ) VALUES (
          @name, @description, @price, @image_url, @partner_id, @created_at
        ) RETURNING *
        ''',
        params: {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'image_url': product.imageUrl,
          'partner_id': product.partnerId,
          'created_at': product.createdAt ?? DateTime.now(),
        },
      );
      return Products.fromJson(result!);
    } catch (e) {
      print('Ошибка создания продукта: $e');
      rethrow;
    }
  }

  Future<Products> update(Products product) async {
    try {
      final result = await queryOne(
        '''
        UPDATE products 
        SET 
          name = @name,
          description = @description,
          price = @price,
          image_url = @image_url,
          is_available = @is_available
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'image_url': product.imageUrl,
          'is_available': product.isAvailable,
        },
      );
      return Products.fromJson(result!);
    } catch (e) {
      print('Ошибка обновления продукта: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await queryOne(
        'DELETE FROM products WHERE id = @id RETURNING id',
        params: {'id': id},
      );
    } catch (e) {
      print('Ошибка удаления продукта: $e');
      rethrow;
    }
  }

  Future<void> updateProductCategories(int productId, List<int> categoryIds) async {
    try {
      await transaction((txn) async {
        await txn.query('''
          DELETE FROM product_category_map WHERE product_id = @productId
        ''', substitutionValues: {'productId': productId});

        for (final categoryId in categoryIds) {
          await txn.query('''
            INSERT INTO product_category_map (product_id, category_id, created_at)
            VALUES (@productId, @categoryId, @createdAt)
          ''', substitutionValues: {
            'productId': productId,
            'categoryId': categoryId,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      print('Ошибка обновления категорий продукта: $e');
      rethrow;
    }
  }
}