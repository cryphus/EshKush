class PasswordFilter {
  /// Удаляет пароли из данных для безопасного логирования
  static dynamic filterPasswords(dynamic data) {
    if (data is Map<String, dynamic>) {
      final filtered = <String, dynamic>{};
      
      for (final entry in data.entries) {
        final key = entry.key.toLowerCase();
        if (key.contains('password') || key.contains('pass') || key.contains('pwd')) {
          filtered[entry.key] = '[REDACTED]';
        } else if (entry.value is Map<String, dynamic>) {
          filtered[entry.key] = filterPasswords(entry.value);
        } else if (entry.value is List) {
          filtered[entry.key] = (entry.value as List).map((item) => 
            item is Map<String, dynamic> ? filterPasswords(item) : item).toList();
        } else {
          filtered[entry.key] = entry.value;
        }
      }
      
      return filtered;
    } else if (data is List) {
      return data.map((item) => 
        item is Map<String, dynamic> ? filterPasswords(item) : item).toList();
    } else {
      return data;
    }
  }

  /// Удаляет пароли из строки для безопасного логирования
  static String filterPasswordsInString(String text) {
    // Заменяем пароли в формате "password: value"
    final passwordPattern = RegExp(r'password[^:]*:[^,}]+', caseSensitive: false);
    return text.replaceAll(passwordPattern, 'password: [REDACTED]');
  }
}
