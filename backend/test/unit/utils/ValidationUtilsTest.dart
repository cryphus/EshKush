import 'package:test/test.dart';
import 'package:backend/utils/ValidationUtils.dart';

void main() {
  // ─── isValidEmail ────────────────────────────────────────────────────────────
  group('isValidEmail', () {
    final valid = [
      'user@example.com',
      'user.name+tag@sub.domain.io',
      'a@b.ru',
    ];
    final invalid = [
      '',
      'no-at-sign',
      '@nodomain.com',
      'user@',
      'user @example.com',
      'user@example', // нет TLD
    ];

    for (final email in valid) {
      test('действительный: $email',
          () => expect(ValidationUtils.isValidEmail(email), isTrue));
    }
    for (final email in invalid) {
      test('недействительный: "$email"',
          () => expect(ValidationUtils.isValidEmail(email), isFalse));
    }
  });

  // ─── isValidPassword ─────────────────────────────────────────────────────────
  group('isValidPassword', () {
    test('валидный пароль проходит', () {
      expect(ValidationUtils.isValidPassword('Secret@1234'), isTrue);
      expect(ValidationUtils.isValidPassword('P@ssw0rd!'), isTrue);
    });

    test('слишком короткий (< 8) → false', () {
      expect(ValidationUtils.isValidPassword('Ab1!'), isFalse);
    });

    test('без заглавной буквы → false', () {
      expect(ValidationUtils.isValidPassword('secret@1234'), isFalse);
    });

    test('без строчной буквы → false', () {
      expect(ValidationUtils.isValidPassword('SECRET@1234'), isFalse);
    });

    test('без цифры → false', () {
      expect(ValidationUtils.isValidPassword('Secret@abcd'), isFalse);
    });

    test('без спецсимвола → false', () {
      expect(ValidationUtils.isValidPassword('Secret1234'), isFalse);
    });

    test('слишком длинный (> 100) → false', () {
      final long = 'Aa1!' * 26; // 104 символа
      expect(ValidationUtils.isValidPassword(long), isFalse);
    });
  });

  // ─── isValidName ─────────────────────────────────────────────────────────────
  group('isValidName', () {
    test('обычное имя проходит', () {
      expect(ValidationUtils.isValidName('Иван Иванов'), isTrue);
      expect(ValidationUtils.isValidName('BestPartner'), isTrue);
      expect(
          ValidationUtils.isValidName('Кафе №1'), isFalse); // № не в паттерне
    });

    test('пустое → false',
        () => expect(ValidationUtils.isValidName(''), isFalse));

    test('длиннее 100 → false', () {
      expect(ValidationUtils.isValidName('А' * 101), isFalse);
    });

    test('ровно 100 → true', () {
      expect(ValidationUtils.isValidName('А' * 100), isTrue);
    });
  });

  // ─── isValidDescription ──────────────────────────────────────────────────────
  group('isValidDescription', () {
    test('пустое → true (опционально)',
        () => expect(ValidationUtils.isValidDescription(''), isTrue));
    test('1000 символов → true',
        () => expect(ValidationUtils.isValidDescription('x' * 1000), isTrue));
    test('1001 символ → false',
        () => expect(ValidationUtils.isValidDescription('x' * 1001), isFalse));
  });

  // ─── isValidCode ─────────────────────────────────────────────────────────────
  group('isValidCode', () {
    test('буквы, цифры, дефис, подчёркивание → true', () {
      expect(ValidationUtils.isValidCode('promo-2024_AB'), isTrue);
    });

    test('пустое → false',
        () => expect(ValidationUtils.isValidCode(''), isFalse));
    test('пробел → false',
        () => expect(ValidationUtils.isValidCode('code with space'), isFalse));
    test('длиннее 50 → false',
        () => expect(ValidationUtils.isValidCode('a' * 51), isFalse));
    test('ровно 50 → true',
        () => expect(ValidationUtils.isValidCode('a' * 50), isTrue));
  });

  // ─── isValidNotes ────────────────────────────────────────────────────────────
  group('isValidNotes', () {
    test('пустое → true',
        () => expect(ValidationUtils.isValidNotes(''), isTrue));
    test('500 символов → true',
        () => expect(ValidationUtils.isValidNotes('x' * 500), isTrue));
    test('501 символ → false',
        () => expect(ValidationUtils.isValidNotes('x' * 501), isFalse));
  });

  // ─── isValidNumber ───────────────────────────────────────────────────────────
  group('isValidNumber', () {
    test('null → false',
        () => expect(ValidationUtils.isValidNumber(null), isFalse));
    test('нечисловая строка → false',
        () => expect(ValidationUtils.isValidNumber('abc'), isFalse));
    test('целое число → true',
        () => expect(ValidationUtils.isValidNumber(42), isTrue));
    test('строка-число → true',
        () => expect(ValidationUtils.isValidNumber('3.14'), isTrue));

    test('ниже min → false',
        () => expect(ValidationUtils.isValidNumber(0, min: 1.0), isFalse));
    test('равно min → true',
        () => expect(ValidationUtils.isValidNumber(1, min: 1.0), isTrue));
    test('выше max → false',
        () => expect(ValidationUtils.isValidNumber(6, max: 5.0), isFalse));
    test('равно max → true',
        () => expect(ValidationUtils.isValidNumber(5, max: 5.0), isTrue));
    test(
        'в диапазоне → true',
        () => expect(
            ValidationUtils.isValidNumber(3, min: 1.0, max: 5.0), isTrue));
  });

  // ─── isValidDate ─────────────────────────────────────────────────────────────
  group('isValidDate', () {
    test('ISO8601 → true',
        () => expect(ValidationUtils.isValidDate('2024-06-15'), isTrue));
    test(
        'datetime с T → true',
        () =>
            expect(ValidationUtils.isValidDate('2024-06-15T10:30:00'), isTrue));
    test('некорректная дата → false',
        () => expect(ValidationUtils.isValidDate('not-a-date'), isFalse));
    test('пустое → false',
        () => expect(ValidationUtils.isValidDate(''), isFalse));
  });

  // ─── sanitizeString ──────────────────────────────────────────────────────────
  group('sanitizeString', () {
    test('убирает HTML-теги', () {
      expect(ValidationUtils.sanitizeString('<b>текст</b>'), equals('текст'));
    });

    test('убирает скрипт', () {
      expect(ValidationUtils.sanitizeString('<script>alert(1)</script>'),
          isNot(contains('<script>')));
    });

    test('декодирует HTML-сущности', () {
      expect(ValidationUtils.sanitizeString('a &amp; b'), equals('a & b'));
    });

    test('trim пробелов', () {
      expect(ValidationUtils.sanitizeString('  привет  '), equals('привет'));
    });

    test('обычная строка не меняется', () {
      expect(
          ValidationUtils.sanitizeString('Hello World'), equals('Hello World'));
    });
  });

  // ─── sanitizeJson ────────────────────────────────────────────────────────────
  group('sanitizeJson', () {
    test('строковые значения обрабатываются', () {
      final result =
          ValidationUtils.sanitizeJson({'name': '<b>Тест</b>', 'count': 42});
      expect(result['name'], equals('Тест'));
      expect(result['count'], equals(42));
    });

    test('вложенные объекты рекурсивно санитизируются', () {
      final result = ValidationUtils.sanitizeJson({
        'nested': {'value': '<script>evil</script>'},
      });
      expect((result['nested'] as Map)['value'], isNot(contains('<script>')));
    });

    test('списки строк санитизируются', () {
      final result = ValidationUtils.sanitizeJson({
        'tags': ['<b>один</b>', '<i>два</i>'],
      });
      final tags = result['tags'] as List;
      expect(tags[0], equals('один'));
      expect(tags[1], equals('два'));
    });
  });

  // ─── validateAndSanitizeOrderData ────────────────────────────────────────────
  group('validateAndSanitizeOrderData', () {
    final valid = {
      'orderId': 1,
      'pointId': 2,
      'userId': 3,
      'orderDate': '2024-06-15',
    };

    test('корректные данные → нет исключения', () {
      expect(() => ValidationUtils.validateAndSanitizeOrderData(valid),
          returnsNormally);
    });

    test('возвращает нормализованные поля', () {
      final result = ValidationUtils.validateAndSanitizeOrderData(valid);
      expect(result['orderId'], isNotNull);
      expect(result['userId'], isNotNull);
      expect(result['orderDate'], isNotNull);
    });

    test('отсутствует orderId → ValidationException', () {
      final data = Map<String, dynamic>.from(valid)..remove('orderId');
      expect(
        () => ValidationUtils.validateAndSanitizeOrderData(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('отсутствует orderDate → ValidationException', () {
      final data = Map<String, dynamic>.from(valid)..remove('orderDate');
      expect(
        () => ValidationUtils.validateAndSanitizeOrderData(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('некорректный orderId (< 1) → ValidationException', () {
      final data = Map<String, dynamic>.from(valid)..['orderId'] = 0;
      expect(
        () => ValidationUtils.validateAndSanitizeOrderData(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('некорректная дата → ValidationException', () {
      final data = Map<String, dynamic>.from(valid)
        ..['orderDate'] = 'not-a-date';
      expect(
        () => ValidationUtils.validateAndSanitizeOrderData(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('принимает snake_case ключи (order_id, point_id, user_id, order_date)',
        () {
      final snaked = {
        'order_id': 1,
        'point_id': 2,
        'user_id': 3,
        'order_date': '2024-01-01',
      };
      expect(() => ValidationUtils.validateAndSanitizeOrderData(snaked),
          returnsNormally);
    });
  });

  // ─── validateAndSanitizeActionData ───────────────────────────────────────────
  group('validateAndSanitizeActionData', () {
    final valid = {
      'orderId': 1,
      'partnerId': 2,
      'actionDescription': 'Принято в обработку',
    };

    test('корректные данные → нет исключения', () {
      expect(() => ValidationUtils.validateAndSanitizeActionData(valid),
          returnsNormally);
    });

    test('отсутствует orderId → ValidationException', () {
      final d = Map<String, dynamic>.from(valid)..remove('orderId');
      expect(() => ValidationUtils.validateAndSanitizeActionData(d),
          throwsA(isA<ValidationException>()));
    });

    test('отсутствует partnerId → ValidationException', () {
      final d = Map<String, dynamic>.from(valid)..remove('partnerId');
      expect(() => ValidationUtils.validateAndSanitizeActionData(d),
          throwsA(isA<ValidationException>()));
    });

    test('отсутствует actionDescription → ValidationException', () {
      final d = Map<String, dynamic>.from(valid)..remove('actionDescription');
      expect(() => ValidationUtils.validateAndSanitizeActionData(d),
          throwsA(isA<ValidationException>()));
    });
  });

  // ─── UserValidationUtils ─────────────────────────────────────────────────────
  group('UserValidationUtils', () {
    group('isValidPhoneNumber', () {
      final valid = [
        '+79991234567',
        '89991234567',
        '79991234567',
        '+12345678901'
      ];
      final invalid = ['', '123', 'abc', '+7abc1234567'];

      for (final p in valid) {
        test('действительный: $p',
            () => expect(UserValidationUtils.isValidPhoneNumber(p), isTrue));
      }
      for (final p in invalid) {
        test('недействительный: "$p"',
            () => expect(UserValidationUtils.isValidPhoneNumber(p), isFalse));
      }
    });

    group('isValidUsername', () {
      test('3–30 символов буквы/цифры/подчёркивание → true', () {
        expect(UserValidationUtils.isValidUsername('user_123'), isTrue);
      });
      test('2 символа → false',
          () => expect(UserValidationUtils.isValidUsername('ab'), isFalse));
      test('31 символ → false',
          () => expect(UserValidationUtils.isValidUsername('a' * 31), isFalse));
      test(
          'пробел → false',
          () => expect(
              UserValidationUtils.isValidUsername('user name'), isFalse));
    });

    group('isValidUserRole', () {
      test('допустимые роли', () {
        for (final r in ['guest', 'user', 'partner', 'support', 'admin']) {
          expect(UserValidationUtils.isValidUserRole(r), isTrue, reason: r);
        }
      });
      test('несуществующая роль → false', () {
        expect(UserValidationUtils.isValidUserRole('superadmin'), isFalse);
      });
    });

    group('validateUserRegistrationData', () {
      final valid = {
        'username': 'testuser',
        'password': 'Secret@1234',
        'password_confirm': 'Secret@1234',
        'email': 'test@example.com',
        'number': '+79991234567',
      };

      test('корректные данные → пустая карта ошибок', () {
        expect(
            UserValidationUtils.validateUserRegistrationData(valid), isEmpty);
      });

      test('пароли не совпадают → ошибка password_confirm', () {
        final d = Map<String, dynamic>.from(valid)
          ..['password_confirm'] = 'OtherPass@1';
        expect(UserValidationUtils.validateUserRegistrationData(d),
            contains('password_confirm'));
      });

      test('некорректный email → ошибка email', () {
        final d = Map<String, dynamic>.from(valid)..['email'] = 'not-email';
        expect(UserValidationUtils.validateUserRegistrationData(d),
            contains('email'));
      });

      test('слабый пароль → ошибка password', () {
        final d = Map<String, dynamic>.from(valid)
          ..['password'] = 'weak'
          ..['password_confirm'] = 'weak';
        expect(UserValidationUtils.validateUserRegistrationData(d),
            contains('password'));
      });
    });
  });
}
