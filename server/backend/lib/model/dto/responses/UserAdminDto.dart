import '../../entities/User.dart';

class UserAdminDto {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastLoginIp;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isVerified;

  UserAdminDto({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginIp,
    this.lastLoginAt,
    this.isActive = true,
    this.isVerified = false,
  });

  factory UserAdminDto.fromEntity(User user, {
    String? lastLoginIp,
    DateTime? lastLoginAt,
    bool isActive = true,
    bool isVerified = false,
  }) {
    return UserAdminDto(
      id: user.id,
      username: user.username,
      email: user.email,
      phoneNumber: user.number,
      role: user.role.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginIp: lastLoginIp,
      lastLoginAt: lastLoginAt,
      isActive: isActive,
      isVerified: isVerified,
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
      if (lastLoginIp != null) 'last_login_ip': lastLoginIp,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
      'is_active': isActive,
      'is_verified': isVerified,
    };
  }
}
