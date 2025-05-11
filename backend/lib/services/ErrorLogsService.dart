import '../model/entities/ErrorLogs.dart';
import '../model/enums/ErrorSeverity.dart';
import '../repositories/ErrorLogsRepository.dart';

class ErrorLogsService {
  final ErrorLogsRepository _repository;

  ErrorLogsService(this._repository);

  Future<ErrorLogs> logError({
    required String errorMessage,
    required String errorCode,
    required String stackTrace,
    required ErrorSeverity severity,
    String? module,
    int? userId,
    String? additionalInfo,
  }) async {
    final error = ErrorLogs(
      id: 0, // ID будет присвоен базой данных
      errorMessage: errorMessage,
      errorCode: errorCode,
      stackTrace: stackTrace,
      time: DateTime.now(),
      severity: severity,
      module: module,
      userId: userId,
      additionalInfo: additionalInfo,
    );

    return await _repository.create(error);
  }

  Future<List<ErrorLogs>> getErrorsBySeverity(ErrorSeverity severity) async {
    return await _repository.findBySeverity(severity);
  }

  Future<List<ErrorLogs>> getErrorsByModule(String module) async {
    return await _repository.findByModule(module);
  }

  Future<List<ErrorLogs>> getUserErrors(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<List<ErrorLogs>> getUnresolvedErrors() async {
    return await _repository.findUnresolved();
  }

  Future<List<ErrorLogs>> getRecentErrors({int limit = 100}) async {
    return await _repository.findRecent(limit: limit);
  }

  Future<void> markErrorAsResolved(int errorId, String resolvedBy) async {
    await _repository.markAsResolved(errorId, resolvedBy);
  }
} 