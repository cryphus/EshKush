import '../../entities/Profile.dart';

class ProfileResponseDto {
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

  ProfileResponseDto({
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

  factory ProfileResponseDto.fromEntity(Profile profile) {
    return ProfileResponseDto(
      id: profile.id,
      userId: profile.userId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      sumCO2: profile.sumCO2,
      savedMoney: profile.savedMoney,
      countBuy: profile.countBuy,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      'sum_co2': sumCO2,
      'saved_money': savedMoney,
      'count_buy': countBuy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
