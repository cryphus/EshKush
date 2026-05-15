import 'package:postgres/postgres.dart';
import '../model/entities/Product.dart';
import '../model/entities/ProductCategory.dart';
import '../utils/SafeLoggingUtils.dart';
import 'BaseRepository.dart';
import '../utils/AppException.dart';

class ProductsRepository extends BaseRepository {
  ProductsRepository(PostgreSQLConnection connection) : super(connection) {
    connection.execute('SET client_encoding TO \'UTF8\'');
    connection.execute('SET standard_conforming_strings TO on');
  }

  Future<Product?> findById(int id) async {
    try {
      await connection.execute('SET client_encoding TO \'UTF8\'');
      final result = await queryOne(
        '''
        SELECT 
          id,
          COALESCE(name, '') as name,
          COALESCE(description, '') as description,
          COALESCE(price, 0.0) as price,
          COALESCE(image_url, '') as image_url,
          COALESCE(partner_id, 0) as partner_id,
          COALESCE(point_id, 0) as point_id,
          COALESCE(weight, 0.0) as weight,
          COALESCE(is_available, true) as is_available,
          COALESCE(is_active, true) as is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM products 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : Product.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> findAll({int limit = 20, int offset = 0}) async {
    try {
      await connection.execute('SET client_encoding TO \'UTF8\'');
      final results = await query('''
        SELECT
          id,
          COALESCE(name, '') as name,
          COALESCE(description, '') as description,
          COALESCE(price, 0.0) as price,
          COALESCE(image_url, '') as image_url,
          COALESCE(partner_id, 0) as partner_id,
          COALESCE(point_id, 0) as point_id,
          COALESCE(weight, 0.0) as weight,
          COALESCE(is_available, true) as is_available,
          COALESCE(is_active, true) as is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM products
        ORDER BY id
        LIMIT @limit OFFSET @offset
      ''', params: {'limit': limit, 'offset': offset});
      return results.map((map) => Product.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> findByCategory(int categoryId,
      {int limit = 20, int offset = 0}) async {
    try {
      await connection.execute('SET client_encoding TO \'UTF8\'');
      final results = await connection.mappedResultsQuery('''
        SELECT
          p.id,
          COALESCE(p.name, '') as name,
          COALESCE(p.description, '') as description,
          COALESCE(p.price, 0.0) as price,
          COALESCE(p.image_url, '') as image_url,
          COALESCE(p.partner_id, 0) as partner_id,
          COALESCE(p.point_id, 0) as point_id,
          COALESCE(p.weight, 0.0) as weight,
          COALESCE(p.is_available, true) as is_available,
          COALESCE(p.is_active, true) as is_active,
          to_char(p.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE
            WHEN p.updated_at IS NOT NULL THEN to_char(p.updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM products p
        JOIN product_category_map pcm ON p.id = pcm.product_id
        WHERE pcm.category_id = @categoryId
        ORDER BY p.id
        LIMIT @limit OFFSET @offset
      ''', substitutionValues: {
        'categoryId': categoryId,
        'limit': limit,
        'offset': offset
      });

      return results.map((row) => Product.fromJson(row['products']!)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductCategory>> getCategoriesForProduct(int productId) async {
    try {
      final results = await query(
        '''
        SELECT 
          c.id,
          c.name,
          c.description,
          to_char(c.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM product_categories c
        JOIN product_category_map pcm ON c.id = pcm.category_id
        WHERE pcm.product_id = @productId
        ''',
        params: {'productId': productId},
      );
      return results.map((map) => ProductCategory.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> create(Map<String, dynamic> data) async {
    try {
      await connection.execute('SET client_encoding TO \'UTF8\'');
      await connection.execute('SET standard_conforming_strings TO on');

      SafeLoggingUtils.logData(
          'Р вЂ™РЎвЂ¦Р С•Р Т‘Р Р…РЎвЂ№Р Вµ Р Т‘Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р Р† create',
          data);

      // Р СџРЎР‚Р ВµР С•Р В±РЎР‚Р В°Р В·РЎС“Р ВµР С РЎРѓРЎвЂљРЎР‚Р С•Р С”Р С‘ Р Р† UTF-8
      final name = data['name'] as String;
      final description = data['description'] as String;

      // Р СџРЎР‚Р ВµР С•Р В±РЎР‚Р В°Р В·РЎС“Р ВµР С РЎвЂЎР С‘РЎРѓР В»Р С•Р Р†РЎвЂ№Р Вµ Р В·Р Р…Р В°РЎвЂЎР ВµР Р…Р С‘РЎРЏ
      final price = data['price'] is String
          ? double.parse(data['price'])
          : (data['price'] as num).toDouble();
      final pointId = data['point_id'] is String
          ? int.parse(data['point_id'])
          : (data['point_id'] as num).toInt();
      final partnerId = data['partner_id'] is String
          ? int.parse(data['partner_id'])
          : (data['partner_id'] as num).toInt();
      final weight = data['weight'] is String
          ? double.parse(data['weight'])
          : (data['weight'] as num).toDouble();

      final result = await queryOne(
        '''
        WITH inserted_product AS (
          INSERT INTO products (
            name, description, price, image_url, partner_id, point_id,
            weight, is_available, is_active, created_at
          ) VALUES (
            @name, 
            @description, 
            @price, 
            @image_url, 
            @partner_id, 
            @point_id,
            @weight, 
            @is_available, 
            @is_active, 
            CURRENT_TIMESTAMP
          ) RETURNING *
        )
        SELECT 
          id,
          name,
          COALESCE(description, '') as description,
          price,
          image_url,
          partner_id,
          point_id,
          weight,
          is_available,
          is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM inserted_product
        ''',
        params: {
          'name': name,
          'description': description,
          'price': price,
          'image_url': data['image_url'],
          'partner_id': partnerId,
          'point_id': pointId,
          'weight': weight,
          'is_available': data['is_available'] ?? true,
          'is_active': data['is_active'] ?? true,
        },
      );

      if (result == null) {
        throw const InternalServerException();
      }

      return Product.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> update(Product product) async {
    try {
      final result = await queryOne(
        '''
        WITH updated_product AS (
          UPDATE products 
          SET 
            name = @name,
            description = @description,
            price = @price,
            image_url = @image_url,
            point_id = @point_id,
            weight = @weight,
            is_available = @is_available,
            is_active = @is_active,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = @id
          RETURNING *
        )
        SELECT 
          id,
          name,
          COALESCE(description, '') as description,
          price,
          image_url,
          partner_id,
          point_id,
          weight,
          is_available,
          is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM updated_product
        ''',
        params: {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'image_url': product.imageUrl,
          'point_id': product.pointId,
          'weight': product.weight,
          'is_available': product.isAvailable,
          'is_active': product.isActive,
        },
      );

      return Product.fromJson(result!);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<void> updateProductCategories(
      int productId, List<int> categoryIds) async {
    try {
      await transaction((txn) async {
        await txn.query(
          'DELETE FROM product_category_map WHERE product_id = @productId',
          substitutionValues: {'productId': productId},
        );

        if (categoryIds.isNotEmpty) {
          await txn.query(
            '''
            INSERT INTO product_category_map (product_id, category_id, created_at)
            SELECT @productId, UNNEST(@categoryIds::int[]), CURRENT_TIMESTAMP
            ''',
            substitutionValues: {
              'productId': productId,
              'categoryIds': categoryIds,
            },
          );
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> findByPointId(int pointId,
      {int limit = 20, int offset = 0}) async {
    try {
      final results = await query(
        '''
        SELECT
          id,
          name,
          COALESCE(description, '') as description,
          price,
          image_url,
          partner_id,
          point_id,
          weight,
          is_available,
          is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM products
        WHERE point_id = @pointId
        ORDER BY id
        LIMIT @limit OFFSET @offset
        ''',
        params: {'pointId': pointId, 'limit': limit, 'offset': offset},
      );
      return results.map((map) => Product.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductCategory?> findCategoryById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          name,
          description,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM product_categories 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : ProductCategory.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> findByIds(List<int> ids) async {
    try {
      final results = await query('''
        SELECT 
          id,
          COALESCE(name, '') as name,
          COALESCE(description, '') as description,
          COALESCE(price, 0.0) as price,
          COALESCE(image_url, '') as image_url,
          COALESCE(partner_id, 0) as partner_id,
          COALESCE(point_id, 0) as point_id,
          COALESCE(weight, 0.0) as weight,
          COALESCE(is_available, true) as is_available,
          COALESCE(is_active, true) as is_active,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM products 
        WHERE id = ANY(@ids)
      ''', params: {'ids': ids});

      return results;
    } catch (e) {
      rethrow;
    }
  }
}
