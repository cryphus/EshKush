class Profile {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? bio;
  final int sumCO2;
  final double savedMoney;
  final int countBuy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
    required this.sumCO2,
    required this.savedMoney,
    required this.countBuy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        sumCO2: json['sum_co2'] as int? ?? 0,
        savedMoney: (json['saved_money'] as num?)?.toDouble() ?? 0.0,
        countBuy: json['count_buy'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'sum_co2': sumCO2,
        'saved_money': savedMoney,
        'count_buy': countBuy,
      };

  String get fullName => '$firstName $lastName'.trim();
}
