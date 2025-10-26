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

class UpdateUserDto {
  final String? username;
  final String? email;
  final String? password;
  final String? phoneNumber;
  final String? role;

  UpdateUserDto({
    this.username,
    this.email,
    this.password,
    this.phoneNumber,
    this.role,
  });

  factory UpdateUserDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final username = json['username']?.toString().trim();
    if (username != null && username.isNotEmpty) {
      if (username.length < 3) {
        errors.add('Username должен быть минимум 3 символа');
      }
      if (!ValidationUtils.isValidName(username)) {
        errors.add('Некорректный username');
      }
    }

    final email = json['email']?.toString().trim();
    if (email != null && email.isNotEmpty) {
      if (!ValidationUtils.isValidEmail(email)) {
        errors.add('Некорректный email');
      }
    }

    final password = json['password']?.toString();
    if (password != null && password.isNotEmpty) {
      if (password.length < 6) {
        errors.add('Пароль должен быть минимум 6 символов');
      }
    }

    final phoneNumber = json['phone_number']?.toString().trim() ?? 
                       json['number']?.toString().trim();
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (!_isValidPhoneNumber(phoneNumber)) {
        errors.add('Некорректный номер телефона');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return UpdateUserDto(
      username: username,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toEntityData() {
    final data = <String, dynamic>{};
    
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (phoneNumber != null) data['number'] = phoneNumber;
    if (role != null) data['role'] = role;
    
    return data;
  }

  bool get hasFields => 
      username != null || 
      email != null || 
      password != null || 
      phoneNumber != null || 
      role != null;

  @override
  String toString() {
    return 'UpdateUserDto(username: $username, email: $email, phoneNumber: $phoneNumber)';
  }
}
