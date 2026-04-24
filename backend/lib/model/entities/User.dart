import '../../utils/AuthUtils.dart';
import '../../utils/ValidationUtils.dart';
import '../enums/UserRole.dart';

class User {
  final int id;
  String username;
  String? _password;
  String? number;
  String? email;
  int? telegramId;
  String? telegramUsername;
  String? firstName;
  String? lastName;
  String? yandexId;
  String? vkId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  UserRole role;

  User({
    required this.id,
    required this.username,
    String? password,
    this.number,
    this.email,
    this.telegramId,
    this.telegramUsername,
    this.firstName,
    this.lastName,
    this.yandexId,
    this.vkId,
    required this.createdAt,
    this.updatedAt,
    this.role = UserRole.user,
  }) : _password = password {
    // Валидация только если значение задано — пустые колонки допустимы
    // для Telegram-only пользователей (email/password/number заполняются позже).
    if (email != null && email!.isNotEmpty && !UserValidationUtils.isValidEmail(email!)) {
      throw ArgumentError('Invalid email format: $email');
    }
    if (number != null && number!.isNotEmpty && !UserValidationUtils.isValidPhoneNumber(number!)) {
      throw ArgumentError('Invalid phone number format: $number');
    }
    if (!UserValidationUtils.isValidUsername(username)) {
      throw ArgumentError('Invalid username format: $username');
    }
  }


  String? get passwordHash => _password;

  bool verifyPassword(String password) {
    final hash = _password;
    if (hash == null || hash.isEmpty) return false;
    return AuthUtils.verifyPassword(password, hash);
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isBusiness => role == UserRole.partner;
  bool get isSupport => role == UserRole.support;
  bool get isGuest => role == UserRole.guest;

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      final user = User(
        id: json['id'] as int,
        username: json['username'] as String,
        password: json['password'] as String?,
        number: json['number'] as String?,
        email: json['email'] as String?,
        telegramId: json['telegram_id'] is int
            ? json['telegram_id'] as int
            : (json['telegram_id'] == null ? null : int.tryParse(json['telegram_id'].toString())),
        telegramUsername: json['telegram_username'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        yandexId: json['yandex_id'] as String?,
        vkId: json['vk_id'] as String?,
        createdAt: json['created_at'] != null
            ? (json['created_at'] is DateTime
                ? json['created_at'] as DateTime
                : DateTime.parse(json['created_at'] as String))
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? (json['updated_at'] is DateTime
                ? json['updated_at'] as DateTime
                : DateTime.parse(json['updated_at'] as String))
            : null,
        role: UserRole.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['role'] as String).toLowerCase(),
          orElse: () => UserRole.user,
        ),
      );
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      // Пароль НЕ включается в JSON для безопасности
      'number': number,
      'email': email,
      'telegramId': telegramId,
      'telegramUsername': telegramUsername,
      'firstName': firstName,
      'lastName': lastName,
      'yandexId': yandexId,
      'vkId': vkId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'role': role.name.toLowerCase(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          _password == other._password &&
          number == other.number &&
          email == other.email &&
          telegramId == other.telegramId &&
          telegramUsername == other.telegramUsername &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          yandexId == other.yandexId &&
          vkId == other.vkId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      _password.hashCode ^
      number.hashCode ^
      email.hashCode ^
      telegramId.hashCode ^
      yandexId.hashCode ^
      vkId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      role.hashCode;

  @override
  String toString() =>
      'User(id: $id, username: $username, number: $number, '
      'email: $email, telegramId: $telegramId, role: $role, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
