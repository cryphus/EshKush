import 'package:postgres/postgres.dart';
import '../../utils/AuthUtils.dart';
import '../enums/UserRole.dart';
import 'package:email_validator/email_validator.dart';

class User {
  final int id;
  String username;
  String _password;
  String number;
  String email;
  DateTime created_at;
  UserRole role;
  
  User({
    required this.id,        
    required this.username,  
    required String password,
    required this.number,
    required this.email,
    required this.created_at,
    this.role = UserRole.user,
  }) : _password = password {
    if (!EmailValidator.validate(email)) {
      throw ArgumentError('Invalid email format');
    }
    if (!_isValidPhoneNumber(number)) {
      throw ArgumentError('Invalid phone number format');
    }
  }

  bool _isValidPhoneNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanNumber.startsWith('+') && cleanNumber.length >= 11 && cleanNumber.length <= 14;
  }

  String get passwordHash => _password;
  
  bool verifyPassword(String password) {
    return _password == AuthUtils.hashPassword(password);
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isBusiness => role == UserRole.partner;
  bool get isSupport => role == UserRole.support;
  bool get isGuest => role == UserRole.guest;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      number: json['number'] as String,
      email: json['email'] as String,
      created_at: json['created_at'] is DateTime 
          ? json['created_at'] as DateTime 
          : DateTime.parse(json['created_at'] as String),
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['role'] as String).toLowerCase(),
        orElse: () => UserRole.user,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': _password,
      'number': number,
      'email': email,
      'created_at': created_at.toIso8601String(),
      'role': role.name.toLowerCase(),
    };
  }
}