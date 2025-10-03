import '../model/entities/Product.dart';
import '../model/entities/ProductCategory.dart';
import '../repositories/ProductsRepository.dart';

class ProductsService {
  final ProductsRepository _productsRepository;

  ProductsService(this._productsRepository);

  Future<Product> getProductById(int id) async {
    final product = await _productsRepository.findById(id);
    if (product == null) throw Exception('Продукт не найден');
    return product;
  }

  Future<List<Product>> getAllProducts() async {
    return await _productsRepository.findAll();
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    return await _productsRepository.findByCategory(categoryId);
  }

  Future<List<ProductCategory>> getProductCategories(int productId) async {
    try {
      return await _productsRepository.getCategoriesForProduct(productId);
    } catch (e) {
      print('Ошибка получения категорий продукта: $e');
      rethrow;
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      _validateProductData(data);
      return await _productsRepository.create(data);
    } catch (e) {
      print('Ошибка создания продукта: $e');
      rethrow;
    }
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      _validateProductData(data);
      final existingProduct = await _productsRepository.findById(id);
      if (existingProduct == null) throw Exception('Продукт не найден');
      
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
      
      return await _productsRepository.update(updatedProduct);
    } catch (e) {
      print('Ошибка обновления продукта: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _productsRepository.delete(id);
    } catch (e) {
      print('Ошибка удаления продукта: $e');
      rethrow;
    }
  }

  Future<List<ProductCategory>> updateProductCategories(int productId, List<int> categoryIds) async {
    try {
      // Проверяем существование продукта
      final product = await _productsRepository.findById(productId);
      if (product == null) {
        throw Exception('Продукт не найден');
      }

      // Проверяем существование всех категорий
      for (final categoryId in categoryIds) {
        final category = await _productsRepository.findCategoryById(categoryId);
        if (category == null) {
          throw Exception('Категория с ID $categoryId не найдена');
        }
      }

      await _productsRepository.updateProductCategories(productId, categoryIds);
      return await _productsRepository.getCategoriesForProduct(productId);
    } catch (e) {
      print('Ошибка обновления категорий продукта: $e');
      rethrow;
    }
  }

  Future<List<Product>> getProductsByPointId(int pointId) async {
    return await _productsRepository.findByPointId(pointId);
  }

  void _validateProductData(Map<String, dynamic> data) {
    if (data['price'] != null && (data['price'] as num) < 0) {
      throw Exception('Цена не может быть отрицательной');
    }
    if (data['weight'] != null && (data['weight'] as num) < 0) {
      throw Exception('Вес не может быть отрицательным');
    }
    if (data['is_active'] != null && data['is_active'] is! bool) {
      throw Exception('Поле is_active должно быть булевым значением');
    }
  }
}