import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../model/enums/ActionType.dart';
import '../model/enums/EntityType.dart';
import '../services/ActionLogService.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';
import 'SecurityMiddleware.dart';

class LoggingMiddleware {
  static const int _maxLoggedBodyBytes = 50 * 1024; // 50KB

  static Middleware requestResponseLogger(
      {ActionLogService? actionLogService}) {
    return (Handler innerHandler) {
      return (Request request) async {
        final incomingReqId =
            request.headers['x-request-id'] ?? request.headers['X-Request-Id'];
        final requestId = (incomingReqId != null && incomingReqId.isNotEmpty)
            ? incomingReqId
            : _generateRequestId();
        final stopwatch = Stopwatch()..start();
        // Игнорируем preflight и health-пробы оркестратора
        if (request.method == 'OPTIONS') {
          return innerHandler(request);
        }
        if (request.url.path == 'health' ||
            request.url.path.startsWith('health/')) {
          return innerHandler(request);
        }

        final maskedHeaders = _maskHeaders(request.headers);
        String? bodyString;
        final clientIp = SecurityMiddleware.extractClientIp(request);

        // Читаем тело безопасно только для методов с телом.
        // Если Content-Length известен и больше лимита — не читаем тело вовсе:
        // незачем тащить 100MB в память ради лога.
        if (_hasBody(request) &&
            !_skipBodyLoggingForPath(request.requestedUri)) {
          final declaredLength =
              int.tryParse(request.headers['content-length'] ?? '');
          final skip =
              declaredLength != null && declaredLength > _maxLoggedBodyBytes;

          if (!skip) {
            final bytes = await request.read().toList();
            final flattened = bytes.expand((b) => b).toList(growable: false);
            final limited = flattened.length > _maxLoggedBodyBytes
                ? flattened.sublist(0, _maxLoggedBodyBytes)
                : flattened;
            bodyString = utf8.decode(limited, allowMalformed: true);
            bodyString = SafeLoggingUtils.sanitizeString(bodyString);

            // Восстанавливаем тело для следующего обработчика
            request = request.change(
                body: Stream<List<int>>.fromIterable([flattened]));
          }
        }

        // Логируем без тела
        _printJson({
          'ts': DateTime.now().toIso8601String(),
          'level': 'info',
          'event': 'request',
          'requestId': requestId,
          'method': request.method,
          'url': request.requestedUri.toString(),
          'headers': maskedHeaders,
          'clientIp': clientIp,
        });
        if (bodyString != null && bodyString.isNotEmpty) {
          _printJson({
            'ts': DateTime.now().toIso8601String(),
            'level': 'debug',
            'event': 'request_body',
            'requestId': requestId,
            'body': bodyString,
          });
        }

        // Вызов следующего обработчика
        Response response;
        try {
          response = await innerHandler(
            request
                .change(context: {...request.context, 'requestId': requestId}),
          );
        } catch (e, stackTrace) {
          await LoggingUtils.logError('Unhandled exception', e,
              requestId: requestId, stackTrace: stackTrace);
          response = ErrorResponseUtils.errorResponse(
            e,
            requestId: requestId,
            forceCode: ErrorCode.internalError,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers':
                  'Origin, Content-Type, Accept, Authorization',
            },
          );
        }

        // Лог ответа (без чтения тела, чтобы не ломать стримы)
        final headers = _maskHeaders(response.headers);
        stopwatch.stop();
        _printJson({
          'ts': DateTime.now().toIso8601String(),
          'level': 'info',
          'event': 'response',
          'requestId': requestId,
          'status': response.statusCode,
          'headers': headers,
          'durationMs': stopwatch.elapsedMilliseconds,
        });

        // Non-blocking audit trail for authenticated mutating requests.
        if (actionLogService != null && _shouldAudit(request)) {
          unawaited(_auditRequest(
            request: request,
            response: response,
            requestId: requestId,
            actionLogService: actionLogService,
          ));
        }

        // Добавляем X-Request-Id в ответ
        return response.change(headers: {
          ...response.headers,
          'X-Request-Id': requestId,
        });
      };
    };
  }

  static bool _hasBody(Request request) {
    switch (request.method.toUpperCase()) {
      case 'POST':
      case 'PUT':
      case 'PATCH':
        return true;
      default:
        return false;
    }
  }

  static Map<String, String> _maskHeaders(Map<String, String> headers) {
    final masked = <String, String>{};
    for (final entry in headers.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keyLower == 'authorization' ||
          keyLower == 'cookie' ||
          keyLower == 'set-cookie' ||
          keyLower == 'x-api-key') {
        masked[entry.key] = '[REDACTED]';
      } else {
        masked[entry.key] = entry.value;
      }
    }
    return masked;
  }

  static bool _skipBodyLoggingForPath(Uri uri) {
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    if (path.startsWith('/auth')) return true;
    if (path == '/login' || path.startsWith('/login')) return true;
    return false;
  }

  static bool _shouldAudit(Request request) {
    final method = request.method.toUpperCase();
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  static Future<void> _auditRequest({
    required Request request,
    required Response response,
    required String requestId,
    required ActionLogService actionLogService,
  }) async {
    try {
      final userId = RequestContextUtils.getUserId(request);
      if (userId == null) return;

      final path = request.requestedUri.path;
      final actionType = _mapActionType(request.method);
      final entityType = _mapEntityType(path);
      final entityId = _extractEntityId(path);
      final details = '${request.method.toUpperCase()} /$path';
      final ipAddress = SecurityMiddleware.extractClientIp(request);
      final userAgent = request.headers['user-agent'];
      final status = response.statusCode;
      final metadata = <String, dynamic>{
        'status_code': status,
        'request_id': requestId,
      };

      if (status >= 400) {
        await actionLogService.logFailedAction(
          userId: userId,
          actionType: actionType,
          targetEntity: entityType,
          targetId: entityId,
          details: details,
          ipAddress: ipAddress,
          userAgent: userAgent,
          errorMessage: 'HTTP $status',
          metadata: metadata,
        );
        return;
      }

      await actionLogService.logAction(
        userId: userId,
        actionType: actionType,
        targetEntity: entityType,
        targetId: entityId,
        details: details,
        ipAddress: ipAddress,
        userAgent: userAgent,
        metadata: metadata,
      );
    } catch (_) {
      // Audit log must never break the main request flow.
    }
  }

  static ActionType _mapActionType(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return ActionType.create;
      case 'PUT':
      case 'PATCH':
        return ActionType.update;
      case 'DELETE':
        return ActionType.delete;
      default:
        return ActionType.other;
    }
  }

  static EntityType _mapEntityType(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final segment = normalized.split('/').first.toLowerCase();
    switch (segment) {
      case 'users':
        return EntityType.user;
      case 'profiles':
        return EntityType.profile;
      case 'points':
        return EntityType.point;
      case 'products':
        return EntityType.product;
      case 'orders':
      case 'order-actions':
      case 'order-history':
        return EntityType.order;
      case 'promo-codes':
        return EntityType.promoCode;
      default:
        return EntityType.other;
    }
  }

  static int _extractEntityId(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    for (final segment in normalized.split('/')) {
      final value = int.tryParse(segment);
      if (value != null) return value;
    }
    return 0;
  }

  static String _generateRequestId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = (millis * 2654435761) ^ (millis << 13);
    return 'req-$millis-${rand & 0xFFFF}';
  }

  static void _printJson(Map<String, dynamic> log) {
    // Простая JSON-печать без внешних зависимостей
    try {
      final json = jsonEncode(log);
      print(json);
    } catch (_) {
      print(log.toString());
    }
  }
}
