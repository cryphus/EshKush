import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';

class ValidationUtils {
  static final _htmlUnescape = HtmlUnescape();
  
  // Максимальные длины полей
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxPasswordLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxCodeLength = 50;
  static const int maxNotesLength = 500;

  // Валидация email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Валидация пароля
  static bool isValidPassword(String password) {
    if (password.length < 8 || password.length > maxPasswordLength) {
      return false;
    }
    
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUpperCase && hasLowerCase && hasDigits && hasSpecialCharacters;
  }

  // Валидация имени
  static bool isValidName(String name) {
    if (name.isEmpty || name.length > maxNameLength) {
      return false;
    }
    
    final nameRegex = RegExp(r'^[а-яА-Яa-zA-Z\s-]+$');
    return nameRegex.hasMatch(name);
  }

  // Валидация описания
  static bool isValidDescription(String description) {
    return description.length <= 1000;
  }

  // Валидация кода
  static bool isValidCode(String code) {
    if (code.isEmpty || code.length > maxCodeLength) {
      return false;
    }
    
    final codeRegex = RegExp(r'^[a-zA-Z0-9-_]+$');
    return codeRegex.hasMatch(code);
  }

  // Валидация заметок
  static bool isValidNotes(String notes) {
    return notes.isEmpty || notes.length <= maxNotesLength;
  }

  // Валидация числовых значений
  static bool isValidNumber(dynamic value, {double? min, double? max}) {
    if (value == null) return false;
    
    final number = double.tryParse(value.toString());
    if (number == null) return false;
    
    if (min != null && number < min) return false;
    if (max != null && number > max) return false;
    
    return true;
  }

  // Валидация даты
  static bool isValidDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Санитизация строки
  static String sanitizeString(String input) {
    return _htmlUnescape.convert(input)
        .replaceAll(RegExp(r'<[^>]*>'), '') // Удаляем HTML теги
        .replaceAll(RegExp(r'[<>]'), '') // Удаляем оставшиеся < и >
        .trim();
  }

  // Санитизация JSON
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

  // Валидация и санитизация данных заказа
  static Map<String, dynamic> validateAndSanitizeOrderData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String, String>{};

    // Валидация обязательных полей
    if (sanitized['orderId'] == null) {
      errors['orderId'] = 'ID заказа обязателен';
    } else if (!isValidNumber(sanitized['orderId'], min: 1)) {
      errors['orderId'] = 'Некорректный ID заказа';
    }

    if (sanitized['pointId'] == null) {
      errors['pointId'] = 'ID точки обязателен';
    } else if (!isValidNumber(sanitized['pointId'], min: 1)) {
      errors['pointId'] = 'Некорректный ID точки';
    }

    if (sanitized['userId'] == null) {
      errors['userId'] = 'ID пользователя обязателен';
    } else if (!isValidNumber(sanitized['userId'], min: 1)) {
      errors['userId'] = 'Некорректный ID пользователя';
    }

    if (sanitized['orderDate'] == null) {
      errors['orderDate'] = 'Дата заказа обязательна';
    } else if (!isValidDate(sanitized['orderDate'])) {
      errors['orderDate'] = 'Некорректная дата заказа';
    }

    // Валидация опциональных полей
    if (sanitized['totalSum'] != null && !isValidNumber(sanitized['totalSum'], min: 0)) {
      errors['totalSum'] = 'Некорректная сумма заказа';
    }

    if (sanitized['notes'] != null && !isValidNotes(sanitized['notes'])) {
      errors['notes'] = 'Некорректные заметки';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.toString());
    }

    return sanitized;
  }

  // Валидация и санитизация данных действия
  static Map<String, dynamic> validateAndSanitizeActionData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String, String>{};

    // Валидация обязательных полей
    if (sanitized['orderId'] == null) {
      errors['orderId'] = 'ID заказа обязателен';
    } else if (!isValidNumber(sanitized['orderId'], min: 1)) {
      errors['orderId'] = 'Некорректный ID заказа';
    }

    if (sanitized['partnerId'] == null) {
      errors['partnerId'] = 'ID партнера обязателен';
    } else if (!isValidNumber(sanitized['partnerId'], min: 1)) {
      errors['partnerId'] = 'Некорректный ID партнера';
    }

    if (sanitized['actionDescription'] == null) {
      errors['actionDescription'] = 'Описание действия обязательно';
    } else if (!isValidDescription(sanitized['actionDescription'])) {
      errors['actionDescription'] = 'Некорректное описание действия';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.toString());
    }

    return sanitized;
  }

  static Map<String, dynamic> validateAndSanitizePointData(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Проверка обязательных полей
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      errors.add('Название точки обязательно');
    }
    
    if (data['address'] == null || data['address'].toString().trim().isEmpty) {
      errors.add('Адрес точки обязателен');
    }
    
    // Валидация координат
    if (data['latitude'] == null || !isValidNumber(data['latitude'], min: -90, max: 90)) {
      errors.add('Некорректная широта');
    }
    
    if (data['longitude'] == null || !isValidNumber(data['longitude'], min: -180, max: 180)) {
      errors.add('Некорректная долгота');
    }
    
    // Валидация рейтинга
    if (data['rating'] != null && !isValidNumber(data['rating'], min: 0, max: 5)) {
      errors.add('Рейтинг должен быть от 0 до 5');
    }
    
    // Валидация описания
    if (data['description'] != null) {
      data['description'] = sanitizeString(data['description'].toString());
      if (!isValidDescription(data['description'])) {
        errors.add('Описание слишком длинное');
      }
    }
    
    // Валидация контактной информации
    if (data['phone'] != null) {
      data['phone'] = sanitizeString(data['phone'].toString());
      if (!isValidPhone(data['phone'])) {
        errors.add('Некорректный формат телефона');
      }
    }
    
    if (data['email'] != null) {
      data['email'] = sanitizeString(data['email'].toString());
      if (!isValidEmail(data['email'])) {
        errors.add('Некорректный формат email');
      }
    }
    
    // Валидация времени работы
    if (data['workingHours'] != null) {
      if (!isValidWorkingHours(data['workingHours'])) {
        errors.add('Некорректный формат времени работы');
      }
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    
    return data;
  }
  
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }
  
  static bool isValidWorkingHours(dynamic workingHours) {
    if (workingHours is! Map<String, dynamic>) return false;
    
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    
    for (final day in days) {
      if (workingHours[day] != null) {
        final hours = workingHours[day].toString().split('-');
        if (hours.length != 2) return false;
        
        if (!timeRegex.hasMatch(hours[0].trim()) || !timeRegex.hasMatch(hours[1].trim())) {
          return false;
        }
      }
    }
    
    return true;
  }

  static Map<String, dynamic> validateAndSanitizeProductData(Map<String, dynamic> data) {
    if (data == null) {
      throw ValidationException('Данные не могут быть null');
    }
    
    final errors = <String>[];
    
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      errors.add('Название продукта обязательно');
    }
    
    if (data['price'] == null || !isValidNumber(data['price'], min: 0)) {
      errors.add('Некорректная цена');
    }
    
    if (data['description'] != null) {
      data['description'] = sanitizeString(data['description'].toString());
      if (!isValidDescription(data['description'])) {
        errors.add('Описание слишком длинное');
      }
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    
    return data;
  }

  static Map<String, dynamic> validateAndSanitizeProfileData(Map<String, dynamic> data) {
    if (data == null) {
      throw ValidationException('Данные не могут быть null');
    }
    
    final errors = <String>[];
    
    if (data['userId'] == null || !isValidNumber(data['userId'], min: 1)) {
      errors.add('Некорректный ID пользователя');
    }
    
    if (data['savedMoney'] != null && !isValidNumber(data['savedMoney'], min: 0)) {
      errors.add('Некорректная сумма сэкономленных денег');
    }
    
    if (data['countBuy'] != null && !isValidNumber(data['countBuy'], min: 0)) {
      errors.add('Некорректное количество покупок');
    }
    
    if (data['sumCO2'] != null && !isValidNumber(data['sumCO2'], min: 0)) {
      errors.add('Некорректная сумма CO2');
    }
    
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    
    return data;
  }
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
} 