import '../model/entities/PointCategory.dart';
import '../repositories/PointCategoryRepository.dart';

class PointCategoryService {
  final PointCategoryRepository _repository;

  PointCategoryService(this._repository);

  Future<PointCategory?> getById(int id) async {
    return await _repository.findById(id);
  }

  Future<List<PointCategory>> getAll() async {
    return await _repository.findAll();
  }

  Future<PointCategory> create(PointCategory category) async {
    return await _repository.create(category);
  }

  Future<PointCategory> update(PointCategory category) async {
    return await _repository.update(category);
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
  }
} 