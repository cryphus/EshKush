import '../model/entities/ActionLog.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';
import '../repositories/ActionLogRepository.dart';

class ActionLogService {
  final ActionLogRepository _repository;

  ActionLogService(this._repository);

  Future<ActionLog> logAction({
    required int userId,
    required ActionType actionType,
    required EntityType targetEntity,
    required int targetId,
    required String details,
    required String ipAddress,
    String? userAgent,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    final log = ActionLog(
      id: 0, // ID будет присвоен базой данных
      userId: userId,
      actionType: actionType,
      targetEntity: targetEntity,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      metadata: metadata,
    );

    return await _repository.create(log);
  }

  Future<void> logFailedAction({
    required int userId,
    required ActionType actionType,
    required EntityType targetEntity,
    required int targetId,
    required String details,
    required String ipAddress,
    required String errorMessage,
    String? userAgent,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    final log = ActionLog(
      id: 0,
      userId: userId,
      actionType: actionType,
      targetEntity: targetEntity,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      isSuccess: false,
      errorMessage: errorMessage,
      metadata: metadata,
    );

    await _repository.create(log);
  }

  Future<List<ActionLog>> getUserLogs(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<List<ActionLog>> getEntityLogs(EntityType entityType, int entityId) async {
    return await _repository.findByEntity(entityType, entityId);
  }

  Future<List<ActionLog>> getActionTypeLogs(ActionType actionType) async {
    return await _repository.findByActionType(actionType);
  }

  Future<List<ActionLog>> getRecentLogs({int limit = 100}) async {
    return await _repository.findRecent(limit: limit);
  }
} 