import 'dart:convert';
import 'package:test/test.dart';
import 'package:backend/utils/ErrorResponseUtils.dart';
import 'package:backend/utils/ValidationUtils.dart';

void main() {
  // ─── ErrorCode.code строки ───────────────────────────────────────────────────
  group('ErrorCode.code', () {
    test('каждый код возвращает верную строку', () {
      expect(ErrorCode.validationError.code, 'VALIDATION_ERROR');
      expect(ErrorCode.unauthorized.code,    'UNAUTHORIZED');
      expect(ErrorCode.forbidden.code,       'FORBIDDEN');
      expect(ErrorCode.notFound.code,        'NOT_FOUND');
      expect(ErrorCode.conflict.code,        'CONFLICT');
      expect(ErrorCode.badRequest.code,      'BAD_REQUEST');
      expect(ErrorCode.internalError.code,   'INTERNAL_ERROR');
    });
  });

  // ─── statusFromCode ──────────────────────────────────────────────────────────
  group('statusFromCode', () {
    test('validationError → 400', () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.validationError), 400));
    test('badRequest → 400',       () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.badRequest),      400));
    test('unauthorized → 401',     () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.unauthorized),    401));
    test('forbidden → 403',        () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.forbidden),       403));
    test('notFound → 404',         () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.notFound),        404));
    test('conflict → 409',         () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.conflict),        409));
    test('internalError → 500',    () => expect(ErrorResponseUtils.statusFromCode(ErrorCode.internalError),   500));
  });

  // ─── errorCodeFromException ──────────────────────────────────────────────────
  group('errorCodeFromException', () {
    test('null → internalError', () {
      expect(ErrorResponseUtils.errorCodeFromException(null), ErrorCode.internalError);
    });

    test('ValidationException → validationError', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(ValidationException('плохие данные')),
        ErrorCode.validationError,
      );
    });

    test('сообщение с "токен" → unauthorized', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('токен истёк')),
        ErrorCode.unauthorized,
      );
    });

    test('сообщение с "не найден" → notFound', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('пользователь не найден')),
        ErrorCode.notFound,
      );
    });

    test('сообщение с "уже существует" → conflict', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('запись уже существует')),
        ErrorCode.conflict,
      );
    });

    test('сообщение с "доступ" → forbidden', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('доступ запрещён')),
        ErrorCode.forbidden,
      );
    });

    test('сообщение с "invalid" → unauthorized', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('invalid token')),
        ErrorCode.unauthorized,
      );
    });

    test('произвольное исключение без ключевых слов → internalError', () {
      expect(
        ErrorResponseUtils.errorCodeFromException(Exception('что-то пошло не так')),
        ErrorCode.internalError,
      );
    });
  });

  // ─── clientSafeErrorMessage ──────────────────────────────────────────────────
  group('clientSafeErrorMessage', () {
    test('ValidationException → возвращает само сообщение', () {
      final e = ValidationException('поле name обязательно');
      expect(ErrorResponseUtils.clientSafeErrorMessage(e), 'поле name обязательно');
    });

    test('произвольное исключение → defaultClientMessage', () {
      expect(
        ErrorResponseUtils.clientSafeErrorMessage(Exception('внутренняя ошибка БД')),
        ErrorResponseUtils.defaultClientMessage,
      );
    });

    test('произвольное исключение с fallback → fallback', () {
      expect(
        ErrorResponseUtils.clientSafeErrorMessage(Exception('ошибка'), fallback: 'моя ошибка'),
        'моя ошибка',
      );
    });

    test('null → defaultClientMessage', () {
      expect(ErrorResponseUtils.clientSafeErrorMessage(null), ErrorResponseUtils.defaultClientMessage);
    });
  });

  // ─── buildBody ───────────────────────────────────────────────────────────────
  group('buildBody', () {
    test('структура: {error: {code, message}}', () {
      final body = ErrorResponseUtils.buildBody(ErrorCode.notFound, 'не найдено');
      expect(body['error'], isA<Map>());
      expect((body['error'] as Map)['code'], 'NOT_FOUND');
      expect((body['error'] as Map)['message'], 'не найдено');
    });

    test('нет лишних ключей на верхнем уровне', () {
      final body = ErrorResponseUtils.buildBody(ErrorCode.badRequest, 'ошибка');
      expect(body.keys, containsAll(['error']));
    });
  });

  // ─── errorResponse (по исключению) ──────────────────────────────────────────
  group('errorResponse', () {
    test('ValidationException → HTTP 400 с VALIDATION_ERROR', () async {
      final resp = ErrorResponseUtils.errorResponse(ValidationException('плохой email'));
      expect(resp.statusCode, 400);
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect((body['error'] as Map)['code'], 'VALIDATION_ERROR');
      expect((body['error'] as Map)['message'], 'плохой email');
    });

    test('Exception("не найден") → HTTP 404', () async {
      final resp = ErrorResponseUtils.errorResponse(Exception('не найден'));
      expect(resp.statusCode, 404);
    });

    test('Content-Type: application/json всегда присутствует', () async {
      final resp = ErrorResponseUtils.errorResponse(Exception('что-то'));
      expect(resp.headers['content-type'], contains('application/json'));
    });

    test('requestId добавляется в тело если передан', () async {
      final resp = ErrorResponseUtils.errorResponse(Exception('ошибка'), requestId: 'req-123');
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect(body['requestId'], 'req-123');
    });

    test('forceCode переопределяет авто-определение кода', () async {
      // Exception без ключевых слов → internalError (500), но forceCode=forbidden (403)
      final resp = ErrorResponseUtils.errorResponse(
        Exception('xyz'),
        forceCode: ErrorCode.forbidden,
      );
      expect(resp.statusCode, 403);
    });
  });

  // ─── errorResponseWithMessage ────────────────────────────────────────────────
  group('errorResponseWithMessage', () {
    test('явный код и сообщение → корректный HTTP-статус', () async {
      final resp = ErrorResponseUtils.errorResponseWithMessage(
        'Поле name обязательно',
        code: ErrorCode.badRequest,
      );
      expect(resp.statusCode, 400);
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect((body['error'] as Map)['code'], 'BAD_REQUEST');
      expect((body['error'] as Map)['message'], 'Поле name обязательно');
    });

    test('по умолчанию код = badRequest', () {
      final resp = ErrorResponseUtils.errorResponseWithMessage('ошибка');
      expect(resp.statusCode, 400);
    });

    test('requestId в теле если передан', () async {
      final resp = ErrorResponseUtils.errorResponseWithMessage('ошибка', requestId: 'x42');
      final body = jsonDecode(await resp.readAsString()) as Map;
      expect(body['requestId'], 'x42');
    });
  });
}