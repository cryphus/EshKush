import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'AppException.dart';
import 'ValidationUtils.dart';

/// Стабильные коды ошибок для клиента (без утечки деталей).
enum ErrorCode {
  validationError('VALIDATION_ERROR'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  conflict('CONFLICT'),
  tooManyRequests('TOO_MANY_REQUESTS'),
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
    if (e is AppException) return e.message;
    if (e is FormatException) {
      return 'Некорректный JSON в теле запроса';
    }
    return fallback ?? defaultClientMessage;
  }

  /// Определяет код ошибки строго по типу исключения.
  static ErrorCode errorCodeFromException(dynamic e) {
    if (e == null) return ErrorCode.internalError;
    if (e is ValidationException) return ErrorCode.validationError;
    if (e is NotFoundException) return ErrorCode.notFound;
    if (e is ForbiddenException) return ErrorCode.forbidden;
    if (e is UnauthorizedException) return ErrorCode.unauthorized;
    if (e is ConflictException) return ErrorCode.conflict;
    if (e is TooManyRequestsException) return ErrorCode.tooManyRequests;
    if (e is BadRequestException ||
        e is FormatException ||
        e is ArgumentError) {
      return ErrorCode.badRequest;
    }
    if (e is AppException) return ErrorCode.badRequest;
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
      case ErrorCode.tooManyRequests:
        return 429;
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

  /// Единый ответ об ошибке по исключению: статус, стабильный код, безопасное сообщение.
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

  /// Ответ об ошибке по явному сообщению и коду (без исключения).
  static Response errorResponseWithMessage(
    String message, {
    ErrorCode code = ErrorCode.badRequest,
    String? requestId,
    Map<String, String>? headers,
  }) {
    final status = statusFromCode(code);
    final body = buildBody(code, message);
    if (requestId != null) body['requestId'] = requestId;
    final h = Map<String, String>.from(headers ?? {});
    h['Content-Type'] = 'application/json';
    return Response(status, body: jsonEncode(body), headers: h);
  }
}
