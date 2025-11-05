import '../model/entities/PointReview.dart';
import '../repositories/PointReviewRepository.dart';

class PointReviewService {
  final PointReviewRepository _repository;

  PointReviewService(this._repository);

  Future<PointReview?> getById(int id) async {
    return await _repository.findById(id);
  }

  Future<List<PointReview>> getByPointId(int pointId) async {
    return await _repository.findByPointId(pointId);
  }

  Future<List<PointReview>> getByUserId(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<PointReview> create(PointReview review) async {
    return await _repository.create(review);
  }

  Future<PointReview> update(PointReview review) async {
    return await _repository.update(review);
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
  }
} 