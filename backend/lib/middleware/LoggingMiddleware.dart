import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class LoggingMiddleware {
  static const int _maxLoggedBodyBytes = 50 * 1024; // 50KB

  static Middleware requestResponseLogger() {
    return (Handler innerHandler) {
      return (Request request) async {
        final incomingReqId = request.headers['x-request-id'] ?? request.headers['X-Request-Id'];
        final requestId = (incomingReqId != null && incomingReqId.isNotEmpty) ? incomingReqId : _generateRequestId();
        final stopwatch = Stopwatch()..start();
        // Игнорируем preflight
        if (request.method == 'OPTIONS') {
          return innerHandler(request);
        }

        final maskedHeaders = _maskHeaders(request.headers);
        String? bodyString;
        final clientIp = request.headers['x-forwarded-for']?.split(',').first.trim() 
            ?? request.headers['x-real-ip']
            ?? 'unknown';

        // Читаем тело безопасно только для методов с телом
        if (_hasBody(request) && !_skipBodyLoggingForPath(request.requestedUri)) {
          final bytes = await request.read().toList();
          final flattened = bytes.expand((b) => b).toList(growable: false);
          final limited = flattened.length > _maxLoggedBodyBytes
              ? flattened.sublist(0, _maxLoggedBodyBytes)
              : flattened;
          bodyString = utf8.decode(limited, allowMalformed: true);
          bodyString = SafeLoggingUtils.sanitizeString(bodyString);

          // Восстанавливаем тело для следующего обработчика
          final restoredStream = Stream<List<int>>.fromIterable([flattened]);
          request = request.change(body: restoredStream);
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
            request.change(context: {...request.context, 'requestId': requestId}),
          );
        } catch (e, stackTrace) {
          await LoggingUtils.logError('Unhandled exception', e, requestId: requestId, stackTrace: stackTrace);
          response = ErrorResponseUtils.errorResponse(
            e,
            requestId: requestId,
            forceCode: ErrorCode.internalError,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
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
      if (keyLower == 'authorization' || keyLower == 'cookie' || keyLower == 'set-cookie' || keyLower == 'x-api-key') {
        masked[entry.key] = '[REDACTED]';
      } else {
        masked[entry.key] = entry.value;
      }
    }
    return masked;
  }

  static bool _skipBodyLoggingForPath(Uri uri) {
    final path = '/${uri.path}';
    if (path.startsWith('/auth')) return true;
    if (path == '/login' || path.startsWith('/login')) return true;
    return false;
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


