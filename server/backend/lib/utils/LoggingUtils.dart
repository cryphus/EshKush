import 'dart:convert';
import 'SafeLoggingUtils.dart';
import '../config/AppConfig.dart';

class LoggingUtils {
  static Future<void> logRequest(String method, String path, Map<String, String> headers, String? body, {String? requestId}) async {
    final payload = {
      'ts': DateTime.now().toIso8601String(),
      'level': 'info',
      'event': 'request',
      'requestId': requestId,
      'method': method,
      'path': path,
      'headers': _maskHeaders(headers),
      if (body != null) 'body': SafeLoggingUtils.sanitizeString(body),
    };
    _print(payload);
  }

  static Future<void> logResponse(int statusCode, Map<String, String> headers, String body, {String? requestId}) async {
    final payload = {
      'ts': DateTime.now().toIso8601String(),
      'level': 'info',
      'event': 'response',
      'requestId': requestId,
      'status': statusCode,
      'headers': _maskHeaders(headers),
      'body': SafeLoggingUtils.sanitizeString(body),
    };
    _print(payload);
  }

  static Future<void> logError(String message, dynamic error, {String? requestId}) async {
    final payload = {
      'ts': DateTime.now().toIso8601String(),
      'level': 'error',
      'event': 'error',
      'requestId': requestId,
      'message': message,
      'error': error.toString(),
      'stack': StackTrace.current.toString(),
    };
    _print(payload);
  }

  static Future<void> logInfo(String message, {Map<String, dynamic>? context, String? requestId}) async {
    final payload = {
      'ts': DateTime.now().toIso8601String(),
      'level': 'info',
      'event': 'info',
      'requestId': requestId,
      'message': message,
      if (context != null) 'context': SafeLoggingUtils.sanitizeData(context),
    };
    _print(payload);
  }

  static Future<void> logOrderOperation(String operation, int orderHistoryId, Map<String, dynamic> payload, {String? requestId}) async {
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'level': 'info',
      'event': 'order_history',
      'requestId': requestId,
      'operation': operation,
      'orderHistoryId': orderHistoryId,
      'payload': SafeLoggingUtils.sanitizeData(payload),
    };
    _print(entry);
  }

  static void _print(Map<String, dynamic> entry) {
    final cfg = AppConfig();
    final logJson = cfg.logJson;
    final level = (entry['level'] as String?) ?? 'info';
    final configuredLevel = cfg.logLevel;
    if (!_shouldLog(level, configuredLevel)) return;
    if (logJson) {
      try {
        print(jsonEncode(entry));
        return;
      } catch (_) {}
    }
    print(entry.toString());
  }

  static bool _shouldLog(String level, String configuredLevel) {
    const order = {'debug': 10, 'info': 20, 'warn': 30, 'error': 40};
    final l = order[level] ?? 20;
    final c = order[configuredLevel] ?? 20;
    return l >= c;
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
}