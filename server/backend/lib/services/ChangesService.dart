import '../model/entities/Changes.dart';
import '../model/enums/EntityType.dart';
import '../model/enums/ChangeType.dart';
import '../repositories/ChangesRepository.dart';

class ChangesService {
  final ChangesRepository _repository;

  ChangesService(this._repository);

  Future<Changes> createChange({
    required String entityType,
    required int entityId,
    required String changeType,
    required String fieldName,
    String? oldValue,
    String? newValue,
    int? changedBy,
    String? comment,
  }) async {
    final change = Changes(
      id: 0,
      entityType: entityType,
      entityId: entityId,
      changeType: changeType,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      changedBy: changedBy,
      createdAt: DateTime.now(),
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