import '../model/entities/Changes.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';
import '../repositories/ChangesRepository.dart';

class ChangesService {
  final ChangesRepository _repository;

  ChangesService(this._repository);

  Future<Changes> logChange({
    required EntityType entityType,
    required int entityId,
    required String fieldName,
    required String oldValue,
    required String newValue,
    required int changedBy,
    ChangeType changeType = ChangeType.update,
    String? comment,
  }) async {
    final change = Changes(
      id: 0, // ID будет присвоен базой данных
      entityType: entityType,
      entityId: entityId,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      changedBy: changedBy,
      changedAt: DateTime.now(),
      changeType: changeType,
      comment: comment,
    );

    return await _repository.create(change);
  }

  Future<List<Changes>> getEntityChanges(EntityType entityType, int entityId) async {
    return await _repository.findByEntity(entityType, entityId);
  }

  Future<List<Changes>> getUserChanges(int userId) async {
    return await _repository.findByUser(userId);
  }

  Future<List<Changes>> getChangeTypeChanges(ChangeType changeType) async {
    return await _repository.findByChangeType(changeType);
  }

  Future<List<Changes>> getRecentChanges({int limit = 100}) async {
    return await _repository.findRecent(limit: limit);
  }

  Future<void> revertChange(int changeId, int revertedBy, {String? comment}) async {
    await _repository.revertChange(changeId, revertedBy, comment: comment);
  }
} 