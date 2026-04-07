import '../../../utils/ValidationUtils.dart';

/// Контракт DTO входа: обязательные поля username и password (непустые строки).
class LoginDto {
  final String username;
  final String password;

  LoginDto({
    required this.username,
    required this.password,
  });

  factory LoginDto.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString().trim() ?? '';
    final password = json['password']?.toString() ?? '';

    if (username.isEmpty) {
      throw ValidationException('Username обязателен');
    }
    if (password.isEmpty) {
      throw ValidationException('Password обязателен');
    }

    return LoginDto(
      username: username,
      password: password,
    );
  }

  @override
  String toString() {
    return 'LoginDto(username: $username)';
  }
}
