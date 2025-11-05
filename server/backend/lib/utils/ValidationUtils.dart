import 'package:html_unescape/html_unescape.dart';
import 'SafeLoggingUtils.dart';
import '../model/enums/UserRole.dart';

class ValidationUtils {
  static final _htmlUnescape = HtmlUnescape();
  
  // Максимальные длины полей
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxPasswordLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxCodeLength = 50;
  static const int maxNotesLength = 500;
  static const int maxCategoryNameLength = 100;
  static const int maxCategoryDescriptionLength = 500;
  static const int maxPromoCodeLength = 50;
  static const int maxNotificationMessageLength = 1000;

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
    
    final nameRegex = RegExp(r'^[а-яА-Яa-zA-Z0-9\s\-.,!?()]+$');
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
    SafeLoggingUtils.logData('ValidationUtils: Входящие данные', data);
    final sanitized = sanitizeJson(data);
    SafeLoggingUtils.logData('ValidationUtils: Санитизированные данные', sanitized);
    final errors = <String, String>{};

    // Валидация обязательных полей - проверяем все возможные варианты
    final orderId = sanitized['orderId'] ?? sanitized['order_id'];
    if (orderId == null) {
      errors['orderId'] = 'ID заказа обязателен';
    } else if (!isValidNumber(orderId, min: 1)) {
      errors['orderId'] = 'Некорректный ID заказа';
    }

    final pointId = sanitized['pointId'] ?? sanitized['point_id'];
    if (pointId == null) {
      errors['pointId'] = 'ID точки обязателен';
    } else if (!isValidNumber(pointId, min: 1)) {
      errors['pointId'] = 'Некорректный ID точки';
    }

    final userId = sanitized['userId'] ?? sanitized['user_id'];
    if (userId == null) {
      errors['userId'] = 'ID пользователя обязателен';
    } else if (!isValidNumber(userId, min: 1)) {
      errors['userId'] = 'Некорректный ID пользователя';
    }

    final orderDate = sanitized['orderDate'] ?? sanitized['order_date'];
    if (orderDate == null) {
      errors['orderDate'] = 'Дата заказа обязательна';
    } else if (!isValidDate(orderDate)) {
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

    // Нормализуем поля для возврата
    final result = {
      'orderId': orderId,
      'pointId': pointId,
      'userId': userId,
      'orderDate': orderDate,
      'totalSum': sanitized['totalSum'] ?? sanitized['total_sum'] ?? 0,
      'status': sanitized['status'],
      'notes': sanitized['notes'],
    };
    print('ValidationUtils: Результат валидации: $result');
    return result;
  }

  // Валидация и санитизация заказа (создание)
  static Map<String, dynamic> validateAndSanitizeOrderCreateData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String, String>{};

    if (sanitized['user_id'] == null || !isValidNumber(sanitized['user_id'], min: 1)) {
      errors['user_id'] = 'Некорректный ID пользователя';
    }
    if (sanitized['point_id'] == null || !isValidNumber(sanitized['point_id'], min: 1)) {
      errors['point_id'] = 'Некорректный ID точки';
    }
    if (sanitized['products_id'] == null || sanitized['products_id'] is! List || (sanitized['products_id'] as List).isEmpty) {
      errors['products_id'] = 'Список продуктов обязателен';
    }
    if (sanitized['total_price'] == null || !isValidNumber(sanitized['total_price'], min: 0)) {
      errors['total_price'] = 'Некорректная сумма заказа';
    }
    if (sanitized['partner_id'] != null && !isValidNumber(sanitized['partner_id'], min: 1)) {
      errors['partner_id'] = 'Некорректный ID партнера';
    }
    if (sanitized['date'] != null && sanitized['date'] is String && !isValidDate(sanitized['date'])) {
      errors['date'] = 'Некорректная дата заказа';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.toString());
    }

    return {
      'user_id': int.parse(sanitized['user_id'].toString()),
      'point_id': int.parse(sanitized['point_id'].toString()),
      'products_id': List<dynamic>.from(sanitized['products_id']),
      'total_price': double.parse(sanitized['total_price'].toString()),
      'partner_id': sanitized['partner_id'] != null ? int.parse(sanitized['partner_id'].toString()) : null,
      'date': sanitized['date'] ?? DateTime.now().toIso8601String(),
    };
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

  static Map<String, dynamic> validateAndSanitizePointDataForCreate(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Проверка обязательных полей для создания
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      errors.add('Название точки обязательно');
    }
    
    if (data['address'] == null || data['address'].toString().trim().isEmpty) {
      errors.add('Адрес точки обязателен');
    }

    if (data['city_id'] == null) {
      errors.add('ID города обязателен');
    }

    if (data['partner_id'] == null) {
      errors.add('ID партнера обязателен');
    }

    if (data['latitude'] == null) {
      errors.add('Широта обязательна');
    }

    if (data['longitude'] == null) {
      errors.add('Долгота обязательна');
    }
    
    // Вызываем общую валидацию
    return validateAndSanitizePointData(data);
  }

  static Map<String, dynamic> validateAndSanitizePointDataForUpdate(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Проверка только переданных полей
    if (data['name'] != null && data['name'].toString().trim().isEmpty) {
      errors.add('Название точки не может быть пустым');
    }
    
    if (data['address'] != null && data['address'].toString().trim().isEmpty) {
      errors.add('Адрес точки не может быть пустым');
    }

    if (data['city_id'] != null) {
      try {
        data['city_id'] = int.parse(data['city_id'].toString());
        if (data['city_id'] <= 0) {
          errors.add('Некорректный ID города');
        }
      } catch (e) {
        errors.add('ID города должен быть числом');
      }
    }

    if (data['partner_id'] != null) {
      try {
        data['partner_id'] = int.parse(data['partner_id'].toString());
        if (data['partner_id'] <= 0) {
          errors.add('Некорректный ID партнера');
        }
      } catch (e) {
        errors.add('ID партнера должен быть числом');
      }
    }

    if (data['latitude'] != null) {
      try {
        data['latitude'] = double.parse(data['latitude'].toString());
        if (data['latitude'] < -90 || data['latitude'] > 90) {
          errors.add('Некорректная широта');
        }
      } catch (e) {
        errors.add('Широта должна быть числом');
      }
    }

    if (data['longitude'] != null) {
      try {
        data['longitude'] = double.parse(data['longitude'].toString());
        if (data['longitude'] < -180 || data['longitude'] > 180) {
          errors.add('Некорректная долгота');
        }
      } catch (e) {
        errors.add('Долгота должна быть числом');
      }
    }

    if (data['rating'] != null) {
      try {
        data['rating'] = double.parse(data['rating'].toString());
        if (data['rating'] < 0 || data['rating'] > 5) {
          errors.add('Рейтинг должен быть от 0 до 5');
        }
      } catch (e) {
        errors.add('Рейтинг должен быть числом');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    
    return data;
  }

  static Map<String, dynamic> validateAndSanitizePointData(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Проверка обязательных полей только если они переданы
    if (data['name'] != null && data['name'].toString().trim().isEmpty) {
      errors.add('Название точки не может быть пустым');
    }
    
    if (data['address'] != null && data['address'].toString().trim().isEmpty) {
      errors.add('Адрес точки не может быть пустым');
    }

    // Преобразование и валидация числовых значений
    if (data['city_id'] != null) {
      try {
        data['city_id'] = int.parse(data['city_id'].toString());
        if (data['city_id'] <= 0) {
          errors.add('Некорректный ID города');
        }
      } catch (e) {
        errors.add('ID города должен быть числом');
      }
    }

    if (data['partner_id'] != null) {
      try {
        data['partner_id'] = int.parse(data['partner_id'].toString());
        if (data['partner_id'] <= 0) {
          errors.add('Некорректный ID партнера');
        }
      } catch (e) {
        errors.add('ID партнера должен быть числом');
      }
    }
    
    // Валидация координат
    if (data['latitude'] != null) {
      try {
        data['latitude'] = double.parse(data['latitude'].toString());
        if (data['latitude'] < -90 || data['latitude'] > 90) {
          errors.add('Некорректная широта');
        }
      } catch (e) {
        errors.add('Широта должна быть числом');
      }
    }
    
    if (data['longitude'] != null) {
      try {
        data['longitude'] = double.parse(data['longitude'].toString());
        if (data['longitude'] < -180 || data['longitude'] > 180) {
          errors.add('Некорректная долгота');
        }
      } catch (e) {
        errors.add('Долгота должна быть числом');
      }
    }
    
    // Валидация рейтинга
    if (data['rating'] != null) {
      try {
        data['rating'] = double.parse(data['rating'].toString());
        if (data['rating'] < 0 || data['rating'] > 5) {
          errors.add('Рейтинг должен быть от 0 до 5');
        }
      } catch (e) {
        errors.add('Рейтинг должен быть числом');
      }
    }
    
    // Валидация описания (если поле существует в таблице)
    if (data['description'] != null) {
      data['description'] = sanitizeString(data['description'].toString());
      if (!isValidDescription(data['description'])) {
        errors.add('Описание слишком длинное');
      }
    }
    
    // Валидация контактной информации (если поля существуют в таблице)
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

  static Map<String, dynamic> validateAndSanitizeProductDataForUpdate(Map<String, dynamic> data) {
    final errors = <String>[];

    // Проверка только переданных полей
    if (data['name'] != null) {
      if (!isValidName(data['name'])) {
        errors.add('Некорректное название продукта');
      }
    }

    if (data['description'] != null) {
      if (!isValidDescription(data['description'])) {
        errors.add('Описание продукта не должно превышать 1000 символов');
      }
    }

    if (data['price'] != null) {
      try {
        data['price'] = double.parse(data['price'].toString());
        if (data['price'] < 0) {
          errors.add('Цена продукта должна быть положительным числом');
        }
      } catch (e) {
        errors.add('Цена продукта должна быть числом');
      }
    }

    if (data['point_id'] != null) {
      try {
        data['point_id'] = int.parse(data['point_id'].toString());
        if (data['point_id'] <= 0) {
          errors.add('Некорректный ID точки');
        }
      } catch (e) {
        errors.add('ID точки должен быть числом');
      }
    }

    if (data['partner_id'] != null) {
      try {
        data['partner_id'] = int.parse(data['partner_id'].toString());
        if (data['partner_id'] <= 0) {
          errors.add('Некорректный ID партнера');
        }
      } catch (e) {
        errors.add('ID партнера должен быть числом');
      }
    }

    if (data['weight'] != null) {
      try {
        data['weight'] = double.parse(data['weight'].toString());
        if (data['weight'] < 0) {
          errors.add('Вес продукта должен быть положительным числом');
        }
      } catch (e) {
        errors.add('Вес продукта должен быть числом');
      }
    }

    if (data['is_available'] != null && data['is_available'] is! bool) {
      errors.add('Поле is_available должно быть булевым значением');
    }

    if (data['is_active'] != null && data['is_active'] is! bool) {
      errors.add('Поле is_active должно быть булевым значением');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return data;
  }

  static Map<String, dynamic> validateAndSanitizeProductData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['name'] == null) {
      errors.add('Название продукта обязательно');
    } else if (!isValidName(data['name'])) {
      errors.add('Некорректное название продукта');
    }

    if (data['description'] == null) {
      errors.add('Описание продукта обязательно');
    } else if (!isValidDescription(data['description'])) {
      errors.add('Описание продукта не должно превышать 1000 символов');
    }

    if (data['price'] == null) {
      errors.add('Цена продукта обязательна');
    } else {
      try {
        data['price'] = double.parse(data['price'].toString());
        if (data['price'] < 0) {
          errors.add('Цена продукта должна быть положительным числом');
        }
      } catch (e) {
        errors.add('Цена продукта должна быть числом');
      }
    }

    if (data['point_id'] == null) {
      errors.add('ID точки обязателен');
    } else {
      try {
        data['point_id'] = int.parse(data['point_id'].toString());
        if (data['point_id'] <= 0) {
          errors.add('Некорректный ID точки');
        }
      } catch (e) {
        errors.add('ID точки должен быть числом');
      }
    }

    if (data['partner_id'] == null) {
      errors.add('ID партнера обязателен');
    } else {
      try {
        data['partner_id'] = int.parse(data['partner_id'].toString());
        if (data['partner_id'] <= 0) {
          errors.add('Некорректный ID партнера');
        }
      } catch (e) {
        errors.add('ID партнера должен быть числом');
      }
    }

    if (data['weight'] == null) {
      errors.add('Вес продукта обязателен');
    } else {
      try {
        data['weight'] = double.parse(data['weight'].toString());
        if (data['weight'] < 0) {
          errors.add('Вес продукта должен быть положительным числом');
        }
      } catch (e) {
        errors.add('Вес продукта должен быть числом');
      }
    }

    if (data['is_available'] != null && data['is_available'] is! bool) {
      errors.add('Поле is_available должно быть булевым значением');
    }

    if (data['is_active'] != null && data['is_active'] is! bool) {
      errors.add('Поле is_active должно быть булевым значением');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return data;
  }

  // Валидация категорий продуктов/точек
  static Map<String, dynamic> validateAndSanitizeCategoryData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String>[];
    if (sanitized['name'] == null || sanitized['name'].toString().trim().isEmpty) {
      errors.add('Поле name обязательно');
    } else if (sanitized['name'].toString().length > maxCategoryNameLength) {
      errors.add('Название категории слишком длинное');
    }
    if (sanitized['description'] != null && sanitized['description'].toString().length > maxCategoryDescriptionLength) {
      errors.add('Описание категории слишком длинное');
    }
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    return sanitized;
  }

  // Валидация партнёра (create/update)
  static Map<String, dynamic> validateAndSanitizePartnerData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String>[];
    if (sanitized['user_id'] == null || !isValidNumber(sanitized['user_id'], min: 1)) {
      errors.add('Некорректный ID пользователя');
    }
    if (sanitized['name'] == null || !isValidName(sanitized['name'])) {
      errors.add('Некорректное имя партнера');
    }
    if (sanitized['contact_email'] != null && !isValidEmail(sanitized['contact_email'])) {
      errors.add('Некорректный email контактного лица');
    }
    if (sanitized['contact_phone'] != null && !isValidPhone(sanitized['contact_phone'])) {
      errors.add('Некорректный телефон контактного лица');
    }
    if (sanitized['max_discount'] != null && !isValidNumber(sanitized['max_discount'], min: 0, max: 100)) {
      errors.add('Скидка должна быть в диапазоне 0-100');
    }
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    if (sanitized['max_discount'] != null) {
      sanitized['max_discount'] = double.parse(sanitized['max_discount'].toString());
    }
    return sanitized;
  }

  // Валидация промокода (create/update)
  static Map<String, dynamic> validateAndSanitizePromoCodeData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String>[];
    if (sanitized['code'] == null || sanitized['code'].toString().isEmpty || sanitized['code'].toString().length > maxPromoCodeLength) {
      errors.add('Некорректный код промокода');
    }
    if (sanitized['description'] == null || sanitized['description'].toString().isEmpty) {
      errors.add('Описание обязательно');
    }
    if (sanitized['startDate'] == null || sanitized['endDate'] == null || !isValidDate(sanitized['startDate']) || !isValidDate(sanitized['endDate'])) {
      errors.add('Некорректные даты промокода');
    } else if (DateTime.parse(sanitized['endDate']).isBefore(DateTime.parse(sanitized['startDate']))) {
      errors.add('Дата окончания раньше даты начала');
    }
    if (sanitized['minOrderSum'] == null || !isValidNumber(sanitized['minOrderSum'], min: 0)) {
      errors.add('Некорректная минимальная сумма заказа');
    }
    if (sanitized['discountType'] == null) {
      errors.add('Тип скидки обязателен');
    }
    if (sanitized['discountValue'] == null || !isValidNumber(sanitized['discountValue'], min: 0.01)) {
      errors.add('Некорректное значение скидки');
    }
    if (sanitized['usageLimit'] != null && !isValidNumber(sanitized['usageLimit'], min: 1)) {
      errors.add('Некорректный лимит использования');
    }
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    sanitized['minOrderSum'] = double.parse(sanitized['minOrderSum'].toString());
    sanitized['discountValue'] = double.parse(sanitized['discountValue'].toString());
    return sanitized;
  }

  // Валидация уведомления
  static Map<String, dynamic> validateAndSanitizeNotificationData(Map<String, dynamic> data) {
    final sanitized = sanitizeJson(data);
    final errors = <String>[];
    if (sanitized['userId'] == null || !isValidNumber(sanitized['userId'], min: 1)) {
      errors.add('Некорректный пользователь');
    }
    if (sanitized['message'] == null || sanitized['message'].toString().isEmpty) {
      errors.add('Сообщение обязательно');
    } else if (sanitized['message'].toString().length > maxNotificationMessageLength) {
      errors.add('Сообщение слишком длинное');
    }
    if (sanitized['type'] == null || sanitized['type'].toString().isEmpty) {
      errors.add('Тип уведомления обязателен');
    }
    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
    return sanitized;
  }
  

  static Map<String, dynamic> validateAndSanitizeReviewData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['point_id'] == null) {
      errors.add('ID точки обязателен');
    } else {
      try {
        data['point_id'] = int.parse(data['point_id'].toString());
        if (data['point_id'] <= 0) {
          errors.add('Некорректный ID точки');
        }
      } catch (e) {
        errors.add('ID точки должен быть числом');
      }
    }

    if (data['user_id'] == null) {
      errors.add('ID пользователя обязателен');
    } else {
      try {
        data['user_id'] = int.parse(data['user_id'].toString());
        if (data['user_id'] <= 0) {
          errors.add('Некорректный ID пользователя');
        }
      } catch (e) {
        errors.add('ID пользователя должен быть числом');
      }
    }

    if (data['rating'] == null) {
      errors.add('Рейтинг обязателен');
    } else {
      try {
        data['rating'] = double.parse(data['rating'].toString());
        if (data['rating'] < 0 || data['rating'] > 5) {
          errors.add('Рейтинг должен быть от 0 до 5');
        }
      } catch (e) {
        errors.add('Рейтинг должен быть числом');
      }
    }

    if (data['comment'] != null && data['comment'] is String) {
      final comment = data['comment'] as String;
      if (comment.length > 1000) {
        errors.add('Комментарий не должен превышать 1000 символов');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return {
      'point_id': data['point_id'] as int,
      'user_id': data['user_id'] as int,
      'rating': data['rating'] as double,
      'comment': data['comment'] as String?,
    };
  }

  static Map<String, dynamic> validateAndSanitizeReviewDataForUpdate(Map<String, dynamic> data) {
    final errors = <String>[];

    // Проверка только переданных полей
    if (data['rating'] != null) {
      try {
        data['rating'] = double.parse(data['rating'].toString());
        if (data['rating'] < 0 || data['rating'] > 5) {
          errors.add('Рейтинг должен быть от 0 до 5');
        }
      } catch (e) {
        errors.add('Рейтинг должен быть числом');
      }
    }

    if (data['comment'] != null && data['comment'] is String) {
      final comment = data['comment'] as String;
      if (comment.length > 1000) {
        errors.add('Комментарий не должен превышать 1000 символов');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return {
      'rating': data['rating'] as double?,
      'comment': data['comment'] as String?,
    };
  }

  static Map<String, dynamic> validateAndSanitizeProfileData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Валидация имени
    if (data['first_name'] != null) {
      data['first_name'] = sanitizeString(data['first_name'].toString());
      if (!isValidName(data['first_name'])) {
        errors.add('Некорректное имя');
      }
    }

    // Валидация фамилии
    if (data['last_name'] != null) {
      data['last_name'] = sanitizeString(data['last_name'].toString());
      if (!isValidName(data['last_name'])) {
        errors.add('Некорректная фамилия');
      }
    }

    // Валидация URL аватара
    if (data['avatar_url'] != null && data['avatar_url'] is String) {
      data['avatar_url'] = sanitizeString(data['avatar_url']);
      if (data['avatar_url'].isNotEmpty && !data['avatar_url'].startsWith('http')) {
        errors.add('Некорректный URL аватара');
      }
    }

    // Валидация биографии
    if (data['bio'] != null) {
      data['bio'] = sanitizeString(data['bio'].toString());
      if (data['bio'].length > maxDescriptionLength) {
        errors.add('Биография слишком длинная');
      }
    }

    // Удаляем поля, которых нет в БД
    data.remove('sum_co2');
    data.remove('saved_money');
    data.remove('count_buy');

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

/// Централизованная валидация пользовательских данных
class UserValidationUtils {
  /// Валидация номера телефона
  /// Поддерживает форматы: +7XXXXXXXXXX, 8XXXXXXXXXX, XXXXXXXXXX
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    
    // Убираем все пробелы, дефисы и скобки
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Проверяем различные форматы
    final patterns = [
      r'^\+7\d{10}$',           // +7XXXXXXXXXX (11 цифр с +7)
      r'^8\d{10}$',            // 8XXXXXXXXXX (11 цифр с 8)
      r'^7\d{10}$',            // 7XXXXXXXXXX (11 цифр с 7)
      r'^\+\d{10,15}$',        // +XXXXXXXXXX (10-15 цифр с +)
      r'^\d{10,15}$',          // XXXXXXXXXX (10-15 цифр)
    ];
    
    return patterns.any((pattern) => RegExp(pattern).hasMatch(cleanPhone));
  }
  
  /// Валидация email
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  /// Валидация роли пользователя
  static bool isValidUserRole(String role) {
    if (role.isEmpty) return false;
    
    try {
      // Проверяем, что роль существует в enum
      UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == role.toLowerCase(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Валидация username
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    // Username должен быть 3-30 символов, только буквы, цифры, подчеркивания
    return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username);
  }
  
  /// Валидация пароля
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    // Пароль должен быть минимум 6 символов
    return password.length >= 6;
  }
  
  /// Полная валидация данных пользователя для регистрации
  static Map<String, String> validateUserRegistrationData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    
    // Username
    if (data['username'] == null || data['username'].toString().isEmpty) {
      errors['username'] = 'Имя пользователя обязательно';
    } else if (!isValidUsername(data['username'].toString())) {
      errors['username'] = 'Имя пользователя должно содержать 3-30 символов (буквы, цифры, подчеркивания)';
    }
    
    // Password
    if (data['password'] == null || data['password'].toString().isEmpty) {
      errors['password'] = 'Пароль обязателен';
    } else if (!isValidPassword(data['password'].toString())) {
      errors['password'] = 'Пароль должен содержать минимум 6 символов';
    }
    
    // Email
    if (data['email'] == null || data['email'].toString().isEmpty) {
      errors['email'] = 'Email обязателен';
    } else if (!isValidEmail(data['email'].toString())) {
      errors['email'] = 'Некорректный формат email';
    }
    
    // Phone
    if (data['number'] == null || data['number'].toString().isEmpty) {
      errors['number'] = 'Номер телефона обязателен';
    } else if (!isValidPhoneNumber(data['number'].toString())) {
      errors['number'] = 'Некорректный формат номера телефона';
    }
    
    // Role
    if (data['role'] != null) {
      if (!isValidUserRole(data['role'].toString())) {
        errors['role'] = 'Некорректная роль пользователя';
      }
    }
    
    return errors;
  }
  
  /// Валидация данных пользователя для обновления
  static Map<String, String> validateUserUpdateData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    
    // Username
    if (data['username'] != null) {
      if (data['username'].toString().isEmpty) {
        errors['username'] = 'Имя пользователя не может быть пустым';
      } else if (!isValidUsername(data['username'].toString())) {
        errors['username'] = 'Имя пользователя должно содержать 3-30 символов (буквы, цифры, подчеркивания)';
      }
    }
    
    // Email
    if (data['email'] != null) {
      if (data['email'].toString().isEmpty) {
        errors['email'] = 'Email не может быть пустым';
      } else if (!isValidEmail(data['email'].toString())) {
        errors['email'] = 'Некорректный формат email';
      }
    }
    
    // Phone
    if (data['number'] != null) {
      if (data['number'].toString().isEmpty) {
        errors['number'] = 'Номер телефона не может быть пустым';
      } else if (!isValidPhoneNumber(data['number'].toString())) {
        errors['number'] = 'Некорректный формат номера телефона';
      }
    }
    
    // Role
    if (data['role'] != null) {
      if (!isValidUserRole(data['role'].toString())) {
        errors['role'] = 'Некорректная роль пользователя';
      }
    }
    
    return errors;
  }
} 