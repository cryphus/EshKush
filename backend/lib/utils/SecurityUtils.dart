import 'dart:convert';
import 'dart:math';

import 'package:html_unescape/html_unescape.dart';

class SecurityUtils {
  static final _htmlUnescape = HtmlUnescape();

  /// Unified string sanitizer used across validation and input processing.
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    return _htmlUnescape
        .convert(input)
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[<>]'), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+='), '')
        .replaceAll(RegExp(r'data:', caseSensitive: false), '')
        .replaceAll(RegExp(r'vbscript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'expression\s*\(', caseSensitive: false), '')
        .replaceAll(RegExp(r'url\s*\(', caseSensitive: false), '')
        .trim();
  }

  /// Backward-compatible alias for legacy call sites.
  @Deprecated('Use sanitizeString() instead.')
  static String sanitizeInput(String input) => sanitizeString(input);

  static Map<String, dynamic> sanitizeJson(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    json.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeString(value);
      } else if (value is Map) {
        sanitized[key] = sanitizeJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeString(item);
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

    input = input.replaceAllMapped(
      RegExp(r'\+?[0-9]{10,15}'),
      (match) {
        final phone = match.group(0)!;
        return '${phone.substring(0, 3)}***${phone.substring(phone.length - 4)}';
      },
    );

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
    if (length <= 0) return '';
    final secureRandom = Random.secure();
    final randomBytes =
        List<int>.generate(length * 2, (_) => secureRandom.nextInt(256));
    final encoded = base64Url.encode(randomBytes).replaceAll('=', '');
    return encoded.length <= length ? encoded : encoded.substring(0, length);
  }
}
