/// Typed application exceptions that map directly to HTTP status codes.
/// Throw these instead of generic Exception() to get correct HTTP responses
/// without relying on message string matching in ErrorResponseUtils.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'Ресурс не найден'])
      : super(message);
}

class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'Доступ запрещён'])
      : super(message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Требуется авторизация'])
      : super(message);
}

class ConflictException extends AppException {
  const ConflictException([String message = 'Конфликт данных'])
      : super(message);
}

class BadRequestException extends AppException {
  const BadRequestException([String message = 'Некорректный запрос'])
      : super(message);
}

class ValidationException extends AppException {
  const ValidationException([String message = 'Ошибка валидации'])
      : super(message);
}

class TooManyRequestsException extends AppException {
  const TooManyRequestsException([String message = 'Слишком много запросов'])
      : super(message);
}

class InternalServerException extends AppException {
  const InternalServerException([String message = 'Внутренняя ошибка сервера'])
      : super(message);
}
