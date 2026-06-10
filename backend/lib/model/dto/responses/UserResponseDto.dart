import '../../entities/User.dart';

class UserResponseDto {
  final int id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserResponseDto({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserResponseDto.fromEntity(User user) {
    return UserResponseDto(
      id: user.id,
      username: user.username,
      email: user.email,
      phoneNumber: user.number,
      role: user.role.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserResponseDto(id: $id, username: $username, email: $email, role: $role)';
  }
}
