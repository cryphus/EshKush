import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ErrorLogsService.dart';
import '../utils/ErrorResponseUtils.dart';
import '../model/enums/ErrorSeverity.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/RequestBodyUtils.dart';

class ErrorLogsController {
  final ErrorLogsService _service;

  late final Router _router;

  ErrorLogsController(this._service) {
    _router = Router();
    _router.get('/', getRecentErrors);
    _router.get('/severity', getErrorsBySeverity);
    _router.get('/module', getErrorsByModule);
    _router.get('/user', getUserErrors);
    _router.get('/unresolved', getUnresolvedErrors);
    _router.get('/recent', getRecentErrors);
    _router.post('/resolve', markErrorAsResolved);
    _router.post('/log', logError);
  }

  Router get router => _router;

  Future<Response> getErrorsBySeverity(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final severity = ErrorSeverity.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            request.url.queryParameters['severity'],
        orElse: () => ErrorSeverity.medium,
      );

      final errors = await _service.getErrorsBySeverity(severity);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getErrorsByModule(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final module = request.url.queryParameters['module'] ?? '';
      final errors = await _service.getErrorsByModule(module);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getUserErrors(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '');

      if (userId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID пользователя',
            headers: _getCorsHeaders());
      }

      final errors = await _service.getUserErrors(userId);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getUnresolvedErrors(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final errors = await _service.getUnresolvedErrors();
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> getRecentErrors(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
      final errors = await _service.getRecentErrors(limit: limit);
      return Response.ok(
        jsonEncode(errors.map((error) => error.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> markErrorAsResolved(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final errorId =
          int.tryParse(request.url.queryParameters['errorId'] ?? '');
      final resolvedBy = request.url.queryParameters['resolvedBy'] ?? '';

      if (errorId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID ошибки',
            headers: _getCorsHeaders());
      }

      await _service.markErrorAsResolved(errorId, resolvedBy);
      return Response.ok(
        jsonEncode({'message': 'Ошибка успешно отмечена как решённая'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> logError(Request request) async {
    try {
      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = await RequestBodyUtils.readJsonObject(request);

      if (data['errorMessage'] == null ||
          data['errorCode'] == null ||
          data['stackTrace'] == null ||
          data['severity'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Отсутствуют обязательные поля',
            headers: _getCorsHeaders());
      }

      final severity = ErrorSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
        orElse: () => ErrorSeverity.medium,
      );

      final error = await _service.logError(
        errorMessage: data['errorMessage'],
        errorCode: data['errorCode'],
        stackTrace: data['stackTrace'],
        severity: severity,
        module: data['module'],
        userId: data['userId'],
        additionalInfo: data['additionalInfo'],
      );

      return Response.ok(
        jsonEncode(error.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
