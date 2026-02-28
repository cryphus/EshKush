import '../../../utils/AuthUtils.dart';
import '../../../utils/ValidationUtils.dart';

bool _isValidPhoneNumber(String phone) {
  if (phone.isEmpty) return false;
  final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  final patterns = [
    r'^\+7\d{10}$',
    r'^8\d{10}$',
    r'^7\d{10}$',
    r'^\+\d{10,15}$',
    r'^\d{10,15}$',
  ];
  return patterns.any((pattern) => RegExp(pattern).hasMatch(cleanPhone));
}

class CreateUserDto {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final String? role;

  CreateUserDto({
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.role,
  });

  factory CreateUserDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final username = json['username']?.toString().trim() ?? '';
    if (username.isEmpty || username.length < 3) {
      errors.add('Username должен быть минимум 3 символа');
    }
    if (!ValidationUtils.isValidName(username)) {
      errors.add('Некорректный username');
    }

    final email = json['email']?.toString().trim() ?? '';
    if (email.isEmpty || !ValidationUtils.isValidEmail(email)) {
      errors.add('Некорректный email');
    }

    final password = json['password']?.toString() ?? '';
    if (password.isEmpty) {
      errors.add('Пароль обязателен');
    } else if (!ValidationUtils.isValidPassword(password)) {
      errors.add(
        'Пароль: минимум 8 символов, заглавная и строчная буквы, цифра и спецсимвол (!@#\$%^&*(),.?":{}|<>).',
      );
    }

    final passwordConfirm = json['password_confirm']?.toString() ?? json['passwordConfirm']?.toString() ?? '';
    if (passwordConfirm.isEmpty) {
      errors.add('Подтверждение пароля обязательно');
    } else if (password != passwordConfirm) {
      errors.add('Пароли не совпадают');
    }

    final phoneNumber = json['phone_number']?.toString().trim() ?? 
                       json['number']?.toString().trim() ?? '';
    if (phoneNumber.isEmpty || !_isValidPhoneNumber(phoneNumber)) {
      errors.add('Некорректный номер телефона');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreateUserDto(
      username: username,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toEntityData() {
    return {
      'username': username,
      'email': email,
      'password': AuthUtils.hashPassword(password),
      'number': phoneNumber,
      if (role != null) 'role': role,
    };
  }

  @override
  String toString() {
    return 'CreateUserDto(username: $username, email: $email, phoneNumber: $phoneNumber)';
  }
}
