import '../model/entities/Product.dart';
import '../model/entities/ProductCategory.dart';
import '../repositories/ProductsRepository.dart';
import '../utils/AppException.dart';
import 'CacheService.dart';

class ProductsService {
  final ProductsRepository _productsRepository;
  final CacheService _cacheService;

  ProductsService(this._productsRepository, this._cacheService);

  Future<Product> getProductById(int id) async {
    try {
      // Пытаемся получить из кеша
      final cacheKey = CacheKeys.product(id);
      final cachedProduct = await _cacheService.get<Product>(cacheKey);
      if (cachedProduct != null) {
        return cachedProduct;
      }

      // Если нет в кеше, получаем из БД
      final product = await _productsRepository.findById(id);
      if (product == null) throw const NotFoundException('Продукт не найден');

      // Сохраняем в кеш
      await _cacheService.set(cacheKey, product, ttl: CacheTTL.product);

      return product;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getAllProducts({int limit = 20, int offset = 0}) async {
    try {
      // Кеш только для первой страницы с дефолтными параметрами
      if (limit == 20 && offset == 0) {
        final cacheKey = CacheKeys.allProducts();
        final cachedData = await _cacheService.get<List>(cacheKey);
        if (cachedData != null) {
          return cachedData
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        final products =
            await _productsRepository.findAll(limit: limit, offset: offset);
        await _cacheService.set(cacheKey, products, ttl: CacheTTL.product);
        return products;
      }
      return await _productsRepository.findAll(limit: limit, offset: offset);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCategory(int categoryId,
      {int limit = 20, int offset = 0}) async {
    try {
      if (limit == 20 && offset == 0) {
        final cacheKey = CacheKeys.productsByCategory(categoryId);
        final cachedData = await _cacheService.get<List>(cacheKey);
        if (cachedData != null) {
          return cachedData
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        final products = await _productsRepository.findByCategory(categoryId,
            limit: limit, offset: offset);
        await _cacheService.set(cacheKey, products, ttl: CacheTTL.product);
        return products;
      }
      return await _productsRepository.findByCategory(categoryId,
          limit: limit, offset: offset);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductCategory>> getProductCategories(int productId) async {
    try {
      return await _productsRepository.getCategoriesForProduct(productId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      _validateProductData(data);
      final product = await _productsRepository.create(data);

      // Инвалидируем кеш
      await _invalidateProductCache();

      return product;
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      _validateProductData(data);
      final existingProduct = await _productsRepository.findById(id);
      if (existingProduct == null)
        throw const NotFoundException('Продукт не найден');

      final updatedProduct = Product(
        id: existingProduct.id,
        name: data['name'] ?? existingProduct.name,
        description: data['description'] ?? existingProduct.description,
        price: data['price'] ?? existingProduct.price,
        pointId: data['point_id'] ?? existingProduct.pointId,
        partnerId: data['partner_id'] ?? existingProduct.partnerId,
        weight: data['weight'] ?? existingProduct.weight,
        isAvailable: data['is_available'] ?? existingProduct.isAvailable,
        imageUrl: data['image_url'] ?? existingProduct.imageUrl,
        createdAt: existingProduct.createdAt,
        updatedAt: DateTime.now(),
        isActive: data['is_active'] ?? existingProduct.isActive,
      );

      final result = await _productsRepository.update(updatedProduct);

      // Инвалидируем кеш
      await _invalidateProductCache(id);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _productsRepository.delete(id);

      // Инвалидируем кеш
      await _invalidateProductCache(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductCategory>> updateProductCategories(
      int productId, List<int> categoryIds) async {
    try {
      // Проверяем существование продукта
      final product = await _productsRepository.findById(productId);
      if (product == null) {
        throw const NotFoundException('Продукт не найден');
      }

      // Проверяем существование всех категорий
      for (final categoryId in categoryIds) {
        final category = await _productsRepository.findCategoryById(categoryId);
        if (category == null) {
          throw NotFoundException('Категория с ID $categoryId не найдена');
        }
      }

      await _productsRepository.updateProductCategories(productId, categoryIds);
      final categories =
          await _productsRepository.getCategoriesForProduct(productId);
      await _invalidateProductCache(productId);
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByPointId(int pointId,
      {int limit = 20, int offset = 0}) async {
    return await _productsRepository.findByPointId(pointId,
        limit: limit, offset: offset);
  }

  void _validateProductData(Map<String, dynamic> data) {
    if (data['price'] != null && (data['price'] as num) < 0) {
      throw const BadRequestException('Цена не может быть отрицательной');
    }
    if (data['weight'] != null && (data['weight'] as num) < 0) {
      throw const BadRequestException('Вес не может быть отрицательным');
    }
    if (data['is_active'] != null && data['is_active'] is! bool) {
      throw const BadRequestException(
          'Поле is_active должно быть булевым значением');
    }
  }

  /// Инвалидация кеша продуктов
  Future<void> _invalidateProductCache([int? productId]) async {
    try {
      if (productId != null) {
        // Удаляем конкретный продукт
        await _cacheService.delete(CacheKeys.product(productId));
      }

      // Удаляем списки продуктов (они могут измениться)
      await _cacheService.delete(CacheKeys.allProducts());
      await _cacheService.deleteByPattern('products:category:*');
      await _cacheService.deleteByPattern('products:point:*');
      await _cacheService.deleteByPattern('products:partner:*');
    } catch (e) {
      // Не пробрасываем ошибку, так как это не критично
    }
  }
}
