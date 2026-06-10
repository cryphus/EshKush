import 'package:test/test.dart';
import 'package:backend/model/dto/requests/LoginDto.dart';
import 'package:backend/utils/ValidationUtils.dart';

void main() {
  // ─── Успешное создание ────────────────────────────────────────────────────
  group('LoginDto.fromJson — корректные данные', () {
    test('создаёт DTO без исключений', () {
      expect(
        () => LoginDto.fromJson({'username': 'admin', 'password': 'Secret@1'}),
        returnsNormally,
      );
    });

    test('поля маппятся корректно', () {
      final dto = LoginDto.fromJson({'username': 'admin', 'password': 'MyP@ss1'});
      expect(dto.username, 'admin');
      expect(dto.password, 'MyP@ss1');
    });

    test('username трimmируется', () {
      final dto = LoginDto.fromJson({'username': '  admin  ', 'password': 'pass'});
      expect(dto.username, 'admin');
    });

    test('password НЕ трimmируется (пробелы значимы)', () {
      final dto = LoginDto.fromJson({'username': 'u', 'password': ' pass '});
      expect(dto.password, ' pass ');
    });
  });

  // ─── Пустой / отсутствующий username ─────────────────────────────────────
  group('LoginDto.fromJson — username', () {
    test('пустой username → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'username': '', 'password': 'pass'}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('только пробелы → ValidationException (trim → пустое)', () {
      expect(
        () => LoginDto.fromJson({'username': '   ', 'password': 'pass'}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('null → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'username': null, 'password': 'pass'}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('отсутствует поле username → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'password': 'pass'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── Пустой / отсутствующий password ─────────────────────────────────────
  group('LoginDto.fromJson — password', () {
    test('пустой password → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'username': 'admin', 'password': ''}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('null → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'username': 'admin', 'password': null}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('отсутствует поле password → ValidationException', () {
      expect(
        () => LoginDto.fromJson({'username': 'admin'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── toString не содержит пароль ─────────────────────────────────────────
  group('LoginDto.toString', () {
    test('не раскрывает пароль', () {
      final dto = LoginDto.fromJson({'username': 'admin', 'password': 'SuperSecret@1'});
      expect(dto.toString(), isNot(contains('SuperSecret@1')));
    });

    test('содержит username', () {
      final dto = LoginDto.fromJson({'username': 'admin', 'password': 'pass'});
      expect(dto.toString(), contains('admin'));
    });
  });
}