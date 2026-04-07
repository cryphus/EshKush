import 'package:postgres/postgres.dart';
import '../../utils/AuthUtils.dart';
import '../../utils/SafeLoggingUtils.dart';
import '../../utils/PasswordFilter.dart';
import '../../utils/ValidationUtils.dart';
import '../enums/UserRole.dart';
import 'package:email_validator/email_validator.dart';

class User {
  final int id;
  String username;
  String _password;
  String number;
  String email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  UserRole role;
  
  User({
    required this.id,        
    required this.username,  
    required String password,
    required this.number,
    required this.email,
    required this.createdAt,
    this.updatedAt,
    this.role = UserRole.user,
  }) : _password = password {
    // Валидация данных при создании объекта
    if (!UserValidationUtils.isValidEmail(email)) {
      throw ArgumentError('Invalid email format: $email');
    }
    if (!UserValidationUtils.isValidPhoneNumber(number)) {
      throw ArgumentError('Invalid phone number format: $number');
    }
    if (!UserValidationUtils.isValidUsername(username)) {
      throw ArgumentError('Invalid username format: $username');
    }
  }


  String get passwordHash => _password;
  
  bool verifyPassword(String password) {
    return AuthUtils.verifyPassword(password, _password);
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isBusiness => role == UserRole.partner;
  bool get isSupport => role == UserRole.support;
  bool get isGuest => role == UserRole.guest;

  factory User.fromJson(Map<String, dynamic> json) {
    // Не логируем JSON данные для безопасности
    
    try {
      final user = User(
        id: json['id'] as int,
        username: json['username'] as String,
        password: json['password'] as String,
        number: json['number'] as String,
        email: json['email'] as String,
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
    } catch (e, stackTrace) {
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
      createdAt.hashCode ^
      updatedAt.hashCode ^
      role.hashCode;

  @override
  String toString() =>
      'User(id: $id, username: $username, number: $number, '
      'email: $email, role: $role, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';
}