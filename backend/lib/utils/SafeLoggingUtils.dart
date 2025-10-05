import 'dart:convert';

class SafeLoggingUtils {
  // Список полей, которые не должны попадать в логи
  static const List<String> _sensitiveFields = [
    'password',
    'Password',
    'PASSWORD',
    'pass',
    'Pass',
    'PASS',
    'pwd',
    'Pwd',
    'PWD',
    'secret',
    'Secret',
    'SECRET',
    'token',
    'Token',
    'TOKEN',
    'key',
    'Key',
    'KEY',
    'auth',
    'Auth',
    'AUTH',
    'credential',
    'Credential',
    'CREDENTIAL',
    'private',
    'Private',
    'PRIVATE',
    'ssn', 'card', 'cvv', 'iban', 'pan',
    'authorization', 'cookie', 'set-cookie', 'x-api-key',
  ];

  /// Создает безопасную копию данных для логирования, скрывая чувствительные поля
  static Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (_sensitiveFields.contains(key)) {
        sanitized[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        // Рекурсивно обрабатываем вложенные объекты
        sanitized[key] = sanitizeData(value);
      } else if (value is List) {
        // Обрабатываем списки
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return sanitizeData(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Безопасно логирует данные, автоматически скрывая чувствительные поля
  static void logData(String message, Map<String, dynamic> data) {
    final safeData = sanitizeData(data);
    print('$message: ${jsonEncode(safeData)}');
  }

  /// Безопасно логирует данные с дополнительным контекстом
  static void logDataWithContext(String message, Map<String, dynamic> data, {Map<String, dynamic>? context}) {
    final safeData = sanitizeData(data);
    final safeContext = context != null ? sanitizeData(context) : null;
    
    print('$message:');
    print('  Data: ${jsonEncode(safeData)}');
    if (safeContext != null) {
      print('  Context: ${jsonEncode(safeContext)}');
    }
  }

  /// Проверяет, содержит ли строка чувствительные данные
  static bool containsSensitiveData(String text) {
    return _sensitiveFields.any((field) => text.toLowerCase().contains(field.toLowerCase()));
  }

  /// Создает безопасную строку для логирования, заменяя чувствительные данные
  static String sanitizeString(String text) {
    String sanitized = text;
    
    for (final field in _sensitiveFields) {
      // Заменяем значения чувствительных полей
      final regex = RegExp('$field\\s*[:=]\\s*["\']?[^"\'\\s,}]+["\']?', caseSensitive: false);
      sanitized = sanitized.replaceAll(regex, '$field: [REDACTED]');
    }
    
    return sanitized;
  }
}

