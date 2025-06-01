import '../model/entities/Products.dart';
import '../model/entities/ProductCategory.dart';
import '../repositories/ProductsRepository.dart';

class ProductsService {
  final ProductsRepository _productsRepository;

  ProductsService(this._productsRepository);

  Future<Products> getProductById(int id) async {
    final product = await _productsRepository.findById(id);
    if (product == null) throw Exception('Продукт не найден');
    return product;
  }

  Future<List<Products>> getAllProducts() async {
    return await _productsRepository.findAll();
  }

  Future<List<Products>> getProductsByCategory(int categoryId) async {
    return await _productsRepository.findByCategory(categoryId);
  }

  Future<List<ProductCategory>> getProductCategories(int productId) async {
    return await _productsRepository.getCategoriesForProduct(productId);
  }

  Future<Products> createProduct(Map<String, dynamic> data) async {
    _validateProductData(data);
    final product = Products.fromJson(data);
    return await _productsRepository.create(product);
  }

  Future<Products> updateProduct(int id, Map<String, dynamic> data) async {
    _validateProductData(data);
    final existingProduct = await _productsRepository.findById(id);
    if (existingProduct == null) throw Exception('Продукт не найден');
    final updatedProduct = existingProduct..name = data['name'] ?? existingProduct.name;
    return await _productsRepository.update(updatedProduct);
  }

  Future<void> deleteProduct(int id) async {
    await _productsRepository.delete(id);
  }

  Future<void> updateProductCategories(int productId, List<int> categoryIds) async {
    await _productsRepository.updateProductCategories(productId, categoryIds);
  }

  void _validateProductData(Map<String, dynamic> data) {
    if (data['price'] != null && (data['price'] as double) < 0) {
      throw Exception('Цена не может быть отрицательной');
    }
    if (data['sale'] != null && ((data['sale'] as int) < 0 || data['sale'] > 100)) {
      throw Exception('Скидка должна быть от 0 до 100%');
    }
  }
}