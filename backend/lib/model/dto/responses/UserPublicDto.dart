import '../../entities/User.dart';

class UserPublicDto {
  final int id;
  final String username;
  final String? avatarUrl;
  final String role;

  UserPublicDto({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  factory UserPublicDto.fromEntity(User user) {
    return UserPublicDto(
      id: user.id,
      username: user.username,
      role: user.role.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'role': role,
    };
  }
}
