import 'package:shelf/shelf.dart';
import '../services/ErrorLogsService.dart';
import '../model/enums/ErrorSeverity.dart';

class ErrorLogsController {
  final ErrorLogsService _service;

  ErrorLogsController(this._service);

  Future<Response> getErrorsBySeverity(Request request) async {
    try {
      final severity = ErrorSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == request.url.queryParameters['severity'],
        orElse: () => ErrorSeverity.medium,
      );
      
      final errors = await _service.getErrorsBySeverity(severity);
      return Response.ok(
        errors.map((error) => error.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов по уровню серьезности: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getErrorsByModule(Request request) async {
    try {
      final module = request.url.queryParameters['module'] ?? '';
      final errors = await _service.getErrorsByModule(module);
      return Response.ok(
        errors.map((error) => error.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов по модулю: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getUserErrors(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId'] ?? '');
      final errors = await _service.getUserErrors(userId);
      return Response.ok(
        errors.map((error) => error.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения логов пользователя: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getUnresolvedErrors(Request request) async {
    try {
      final errors = await _service.getUnresolvedErrors();
      return Response.ok(
        errors.map((error) => error.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения нерешенных логов: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getRecentErrors(Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final errors = await _service.getRecentErrors(limit: limit);
      return Response.ok(
        errors.map((error) => error.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка получения последних логов: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> markErrorAsResolved(Request request) async {
    try {
      final errorId = int.parse(request.url.queryParameters['errorId'] ?? '');
      final resolvedBy = request.url.queryParameters['resolvedBy'] ?? '';
      
      await _service.markErrorAsResolved(errorId, resolvedBy);
      return Response.ok(
        {'message': 'Ошибка успешно отмечена как решенная'},
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': 'Ошибка отметки лога как решенного: $e'},
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 