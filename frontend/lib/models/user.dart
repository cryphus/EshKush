enum UserRole { guest, user, partner, support, admin }

UserRole userRoleFromString(String role) {
  return UserRole.values.firstWhere(
    (e) => e.name == role,
    orElse: () => UserRole.guest,
  );
}

class User {
  final int id;
  final String username;
  final String email;
  final String number;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.number,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        number: json['number'] as String? ?? '',
        role: userRoleFromString(json['role'] as String? ?? 'guest'),
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'number': number,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isPartner => role == UserRole.partner;
  bool get isGuest => role == UserRole.guest;
}
