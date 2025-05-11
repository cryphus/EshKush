import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class LoggingUtils {
  static final _sensitiveFields = {
    'password',
    'token',
    'secret',
    'key',
    'authorization',
    'credit_card',
    'card_number',
    'cvv',
    'ssn',
    'social_security',
  };

  static final _logFile = File(path.join(
    Directory.current.path,
    'logs',
    'app_${DateTime.now().toString().split(' ')[0]}.log',
  ));

  static Future<void> init() async {
    final logsDir = Directory(path.join(Directory.current.path, 'logs'));
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    await _log('INFO', 'Logging system initialized', null);
  }

  static Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    await _log('INFO', message, context);
  }

  static Future<void> logError(String message, dynamic error, {Map<String, dynamic>? context}) async {
    await _log('ERROR', message, context, error: error);
  }

  static Future<void> logWarning(String message, {Map<String, dynamic>? context}) async {
    await _log('WARNING', message, context);
  }

  static Future<void> logDebug(String message, {Map<String, dynamic>? context}) async {
    await _log('DEBUG', message, context);
  }

  static Future<void> _log(
    String level,
    String message,
    Map<String, dynamic>? context, {
    dynamic error,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'level': level,
        'message': message,
        if (context != null) 'context': _sanitizeContext(context),
        if (error != null) 'error': _sanitizeError(error),
      };

      final logLine = jsonEncode(logEntry);
      await _logFile.writeAsString('$logLine\n', mode: FileMode.append);
      
      // Также выводим в консоль для разработки
      print('$timestamp [$level] $message');
      if (context != null) {
        print('Context: ${jsonEncode(_sanitizeContext(context))}');
      }
      if (error != null) {
        print('Error: ${_sanitizeError(error)}');
      }
    } catch (e) {
      print('Ошибка логирования: $e');
    }
  }

  static Map<String, dynamic> _sanitizeContext(Map<String, dynamic> context) {
    final sanitized = <String, dynamic>{};
    
    context.forEach((key, value) {
      if (_sensitiveFields.any((field) => key.toLowerCase().contains(field))) {
        sanitized[key] = '***REDACTED***';
      } else if (value is Map) {
        sanitized[key] = _sanitizeContext(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map) {
            return _sanitizeContext(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  static String _sanitizeError(dynamic error) {
    if (error is Map) {
      return jsonEncode(_sanitizeContext(Map<String, dynamic>.from(error)));
    }
    return error.toString();
  }

  // Методы для логирования HTTP-запросов
  static Future<void> logRequest(
    String method,
    String path,
    Map<String, String> headers,
    String? body,
  ) async {
    final sanitizedHeaders = _sanitizeContext(
      headers.map((key, value) => MapEntry(key, value)),
    );
    
    await logInfo(
      'HTTP Request: $method $path',
      context: {
        'headers': sanitizedHeaders,
        if (body != null) 'body': body,
      },
    );
  }

  static Future<void> logResponse(
    int statusCode,
    Map<String, String> headers,
    String? body,
  ) async {
    final sanitizedHeaders = _sanitizeContext(
      headers.map((key, value) => MapEntry(key, value)),
    );
    
    await logInfo(
      'HTTP Response: $statusCode',
      context: {
        'headers': sanitizedHeaders,
        if (body != null) 'body': body,
      },
    );
  }

  // Методы для логирования операций с заказами
  static Future<void> logOrderOperation(
    String operation,
    int orderId,
    Map<String, dynamic>? data,
  ) async {
    await logInfo(
      'Order Operation: $operation',
      context: {
        'orderId': orderId,
        if (data != null) 'data': data,
      },
    );
  }

  // Методы для логирования операций с действиями
  static Future<void> logActionOperation(
    String operation,
    int actionId,
    Map<String, dynamic>? data,
  ) async {
    await logInfo(
      'Action Operation: $operation',
      context: {
        'actionId': actionId,
        if (data != null) 'data': data,
      },
    );
  }
} 