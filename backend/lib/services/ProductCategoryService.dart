import '../model/entities/ProductCategory.dart';
import '../repositories/ProductCategoryRepository.dart';

class ProductCategoryService {
  final ProductCategoryRepository _repository;

  ProductCategoryService(this._repository);

  Future<ProductCategory?> getById(int id) async {
    return await _repository.findById(id);
  }

  Future<List<ProductCategory>> getAll() async {
    return await _repository.findAll();
  }

  Future<ProductCategory> create(ProductCategory category) async {
    return await _repository.create(category);
  }

  Future<ProductCategory> update(ProductCategory category) async {
    return await _repository.update(category);
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
  }
} 