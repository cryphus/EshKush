import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  static final _htmlUnescape = HtmlUnescape();

  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    return input
      .replaceAll(RegExp(r'<[^>]*>'), '') // Удаляем HTML теги
      .replaceAll(RegExp(r'[<>]'), '') // Удаляем оставшиеся < и >
      .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Удаляем javascript: протокол
      .replaceAll(RegExp(r'on\w+='), '') // Удаляем обработчики событий
      .replaceAll(RegExp(r'data:', caseSensitive: false), '') // Удаляем data: протокол
      .replaceAll(RegExp(r'vbscript:', caseSensitive: false), '') // Удаляем vbscript: протокол
      .replaceAll(RegExp(r'expression\s*\(', caseSensitive: false), '') // Удаляем CSS expressions
      .replaceAll(RegExp(r'url\s*\(', caseSensitive: false), '') // Удаляем CSS url()
      .trim();
  }

  static Map<String, dynamic> sanitizeJson(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};
    
    json.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeInput(value);
      } else if (value is Map) {
        sanitized[key] = sanitizeJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeInput(item);
          } else if (item is Map) {
            return sanitizeJson(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  static String maskSensitiveData(String input) {
    if (input.isEmpty) return input;

    // Маскируем email
    input = input.replaceAllMapped(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      (match) {
        final email = match.group(0)!;
        final parts = email.split('@');
        final name = parts[0];
        final domain = parts[1];
        return '${name[0]}***@$domain';
      },
    );

    // Маскируем телефонные номера
    input = input.replaceAllMapped(
      RegExp(r'\+?[0-9]{10,15}'),
      (match) {
        final phone = match.group(0)!;
        return '${phone.substring(0, 3)}***${phone.substring(phone.length - 4)}';
      },
    );

    // Маскируем номера карт
    input = input.replaceAllMapped(
      RegExp(r'\b[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b'),
      (match) {
        final card = match.group(0)!.replaceAll(RegExp(r'[-\s]'), '');
        return '**** **** **** ${card.substring(card.length - 4)}';
      },
    );

    return input;
  }

  static String generateSecureRandomString(int length) {
    final random = DateTime.now().millisecondsSinceEpoch.toString() + 
                  (1000 + DateTime.now().microsecond).toString();
    final bytes = utf8.encode(random);
    final hash = sha256.convert(bytes).bytes;
    return base64Url.encode(hash).substring(0, length);
  }
} 