import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'ValidationUtils.dart';

/// Стабильные коды ошибок для клиента (без утечки деталей).
enum ErrorCode {
  validationError('VALIDATION_ERROR'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  conflict('CONFLICT'),
  badRequest('BAD_REQUEST'),
  internalError('INTERNAL_ERROR');

  final String code;
  const ErrorCode(this.code);
}

class ErrorResponseUtils {
  static const String defaultClientMessage = 'Ошибка обработки запроса';
  static const String serverErrorClientMessage = 'Внутренняя ошибка сервера';

  /// Безопасное сообщение для клиента (без стектрейсов и внутренних деталей).
  static String clientSafeErrorMessage(dynamic e, {String? fallback}) {
    if (e == null) return fallback ?? defaultClientMessage;
    if (e is ValidationException) return e.message;
    return fallback ?? defaultClientMessage;
  }

  /// Определяет код ошибки и HTTP-статус по исключению.
  static ErrorCode errorCodeFromException(dynamic e) {
    if (e == null) return ErrorCode.internalError;
    if (e is ValidationException) return ErrorCode.validationError;
    final msg = e.toString().toLowerCase();
    if (msg.contains('unauthorized') || msg.contains('токен') || msg.contains('авториз')) return ErrorCode.unauthorized;
    if (msg.contains('forbidden') || msg.contains('доступ')) return ErrorCode.forbidden;
    if (msg.contains('not found') || msg.contains('не найден')) return ErrorCode.notFound;
    if (msg.contains('conflict') || msg.contains('уже существует')) return ErrorCode.conflict;
    return ErrorCode.internalError;
  }

  static int statusFromCode(ErrorCode code) {
    switch (code) {
      case ErrorCode.validationError:
      case ErrorCode.badRequest:
        return 400;
      case ErrorCode.unauthorized:
        return 401;
      case ErrorCode.forbidden:
        return 403;
      case ErrorCode.notFound:
        return 404;
      case ErrorCode.conflict:
        return 409;
      case ErrorCode.internalError:
        return 500;
    }
  }

  /// Тело ответа об ошибке: стабильный код + сообщение, без стектрейсов.
  static Map<String, dynamic> buildBody(ErrorCode code, String message) {
    return {
      'error': {
        'code': code.code,
        'message': message,
      },
    };
  }

  /// Единый ответ об ошибке: статус, стабильный код, безопасное сообщение.
  static Response errorResponse(
    dynamic e, {
    String? requestId,
    Map<String, String>? headers,
    ErrorCode? forceCode,
  }) {
    final code = forceCode ?? errorCodeFromException(e);
    final status = statusFromCode(code);
    final message = clientSafeErrorMessage(e);
    final body = buildBody(code, message);
    if (requestId != null) body['requestId'] = requestId;
    final h = Map<String, String>.from(headers ?? {});
    h['Content-Type'] = 'application/json';
    return Response(status, body: jsonEncode(body), headers: h);
  }
}
