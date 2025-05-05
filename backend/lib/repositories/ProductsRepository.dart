import '../model/entities/Products.dart';
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
}