import '../model/entities/UserFavorite.dart';
import '../repositories/UserFavoriteRepository.dart';
import '../utils/AppException.dart';

class UserFavoriteService {
  final UserFavoriteRepository _repository;

  UserFavoriteService(this._repository);

  Future<List<UserFavorite>> getByUserId(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<List<UserFavorite>> getByPointId(int pointId) async {
    return await _repository.findByPointId(pointId);
  }

  Future<UserFavorite> addToFavorites(UserFavorite favorite) async {
    final exists = await _repository.exists(favorite.userId, favorite.pointId);
    if (exists) {
      throw const ConflictException('Место уже добавлено в избранное');
    }
    return await _repository.create(favorite);
  }

  Future<void> removeFromFavorites(int userId, int pointId) async {
    await _repository.delete(userId, pointId);
  }

  Future<bool> isFavorite(int userId, int pointId) async {
    return await _repository.exists(userId, pointId);
  }
}
