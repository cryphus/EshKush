import 'package:test/test.dart';
import 'package:backend/model/dto/requests/CreateUserDto.dart';
import 'package:backend/utils/ValidationUtils.dart';

// Корректный базовый набор полей
Map<String, dynamic> validJson({
  String username = 'testuser',
  String email = 'test@example.com',
  String password = 'Secret@1234',
  String passwordConfirm = 'Secret@1234',
  String number = '+79991234567',
  String? role,
}) =>
    {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'number': number,
      if (role != null) 'role': role,
    };

void main() {
  // ─── Успешное создание ────────────────────────────────────────────────────
  group('CreateUserDto.fromJson — корректные данные', () {
    test('создаёт DTO без исключений', () {
      expect(() => CreateUserDto.fromJson(validJson()), returnsNormally);
    });

    test('поля правильно маппятся', () {
      final dto = CreateUserDto.fromJson(validJson());
      expect(dto.username, 'testuser');
      expect(dto.email, 'test@example.com');
      expect(dto.password, 'Secret@1234');
      expect(dto.phoneNumber, '+79991234567');
      expect(dto.role, isNull);
    });

    test('username трimmируется', () {
      final dto = CreateUserDto.fromJson(validJson(username: '  user123  '));
      expect(dto.username, 'user123');
    });

    test('роль сохраняется если передана', () {
      final dto = CreateUserDto.fromJson(validJson(role: 'partner'));
      expect(dto.role, 'partner');
    });

    test('принимает phone_number вместо number', () {
      final json = validJson()..['phone_number'] = '+79991234567';
      json.remove('number');
      expect(() => CreateUserDto.fromJson(json), returnsNormally);
    });

    test('принимает passwordConfirm (camelCase)', () {
      final json = validJson();
      json['passwordConfirm'] = json.remove('password_confirm')!;
      expect(() => CreateUserDto.fromJson(json), returnsNormally);
    });
  });

  // ─── Валидация username ───────────────────────────────────────────────────
  group('CreateUserDto.fromJson — username', () {
    test('меньше 3 символов → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(username: 'ab')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('содержит пробел → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(username: 'my user')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('31 символ (> 30) → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(username: 'a' * 31)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ровно 3 символа → ОК', () {
      expect(() => CreateUserDto.fromJson(validJson(username: 'abc')), returnsNormally);
    });
  });

  // ─── Валидация email ──────────────────────────────────────────────────────
  group('CreateUserDto.fromJson — email', () {
    test('некорректный email → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(email: 'not-an-email')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('отсутствует @ → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(email: 'userexample.com')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('пустой email → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(email: '')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── Валидация password ───────────────────────────────────────────────────
  group('CreateUserDto.fromJson — password', () {
    test('слабый пароль (нет спецсимвола) → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(
          password: 'Secret1234',
          passwordConfirm: 'Secret1234',
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('пароль < 8 символов → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(password: 'Ab1!', passwordConfirm: 'Ab1!')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('пустой пароль → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(password: '', passwordConfirm: '')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── Подтверждение пароля ─────────────────────────────────────────────────
  group('CreateUserDto.fromJson — password_confirm', () {
    test('пароли не совпадают → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(
          password: 'Secret@1234',
          passwordConfirm: 'Other@Pass1',
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('отсутствует password_confirm → ValidationException', () {
      final json = validJson()..remove('password_confirm');
      expect(
        () => CreateUserDto.fromJson(json),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── Валидация телефона ───────────────────────────────────────────────────
  group('CreateUserDto.fromJson — номер телефона', () {
    final validPhones = ['+79991234567', '89991234567', '79991234567'];
    for (final p in validPhones) {
      test('действительный: $p', () {
        expect(() => CreateUserDto.fromJson(validJson(number: p)), returnsNormally);
      });
    }

    test('слишком короткий номер → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(number: '123')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('пустой номер → ValidationException', () {
      expect(
        () => CreateUserDto.fromJson(validJson(number: '')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── Множественные ошибки ────────────────────────────────────────────────
  group('CreateUserDto.fromJson — несколько ошибок', () {
    test('плохой email + плохой пароль → одно ValidationException с обеими ошибками', () {
      try {
        CreateUserDto.fromJson(validJson(email: 'bad', password: 'weak', passwordConfirm: 'weak'));
        fail('ожидалось исключение');
      } on ValidationException catch (e) {
        expect(e.message, contains('email'));
        expect(e.message, contains('аро'));   // «Пароль»
      }
    });
  });

  // ─── toString не содержит пароль ─────────────────────────────────────────
  group('CreateUserDto.toString', () {
    test('не содержит пароль', () {
      final dto = CreateUserDto.fromJson(validJson());
      expect(dto.toString(), isNot(contains('Secret@1234')));
    });

    test('содержит username и phoneNumber', () {
      final dto = CreateUserDto.fromJson(validJson());
      expect(dto.toString(), contains('testuser'));
      expect(dto.toString(), contains('+79991234567'));
    });
  });
}