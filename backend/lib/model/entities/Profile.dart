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

  Profile({
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

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      firstName: (json['first_name']?.toString() ?? ''),
      lastName: (json['last_name']?.toString() ?? ''),
      avatarUrl: (json['avatar_url'] == null || json['avatar_url'].toString().isEmpty)
          ? null
          : json['avatar_url'].toString(),
      bio: (json['bio'] == null || json['bio'].toString().isEmpty)
          ? null
          : json['bio'].toString(),
      sumCO2: int.tryParse(json['sum_co2']?.toString() ?? '') ?? 0,
      savedMoney: double.tryParse(json['saved_money']?.toString() ?? '') ?? 0.0,
      countBuy: int.tryParse(json['count_buy']?.toString() ?? '') ?? 0,
      createdAt: (() {
        final raw = json['created_at'];
        if (raw is DateTime) return raw;
        final parsed = DateTime.tryParse(raw?.toString() ?? '');
        return parsed ?? DateTime.now();
      })(),
      updatedAt: (() {
        final raw = json['updated_at'];
        if (raw is DateTime) return raw;
        final parsed = DateTime.tryParse(raw?.toString() ?? '');
        return parsed ?? DateTime.now();
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'sum_co2': sumCO2,
      'saved_money': savedMoney,
      'count_buy': countBuy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          avatarUrl == other.avatarUrl &&
          bio == other.bio &&
          sumCO2 == other.sumCO2 &&
          savedMoney == other.savedMoney &&
          countBuy == other.countBuy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      avatarUrl.hashCode ^
      bio.hashCode ^
      sumCO2.hashCode ^
      savedMoney.hashCode ^
      countBuy.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Profile(id: $id, userId: $userId, firstName: $firstName, lastName: $lastName, '
      'avatarUrl: $avatarUrl, bio: $bio, sumCO2: $sumCO2, savedMoney: $savedMoney, '
      'countBuy: $countBuy, createdAt: $createdAt, updatedAt: $updatedAt)';
}