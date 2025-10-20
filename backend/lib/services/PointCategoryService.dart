import '../model/entities/PointCategory.dart';
import '../repositories/PointCategoryRepository.dart';

class PointCategoryService {
  final PointCategoryRepository _repository;

  PointCategoryService(this._repository);

  Future<PointCategory?> getCategory(int id) async {
    return await _repository.findById(id);
  }

  Future<List<PointCategory>> getAllCategories() async {
    return await _repository.findAll();
  }

  Future<PointCategory> createCategory(PointCategory category) async {
    return await _repository.create(category);
  }

  Future<PointCategory> updateCategory(int id, Map<String, dynamic> data) async {
    return await _repository.update(id, data);
  }

  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
  }
} 