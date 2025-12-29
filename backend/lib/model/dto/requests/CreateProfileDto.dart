import '../../../utils/ValidationUtils.dart';

class CreateProfileDto {
  final int userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? bio;

  CreateProfileDto({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
  });

  factory CreateProfileDto.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    final userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) ?? 0 : 0;
    if (userId <= 0) {
      errors.add('Некорректный ID пользователя');
    }

    final firstName = json['first_name']?.toString().trim() ?? '';
    if (firstName.isEmpty || !ValidationUtils.isValidName(firstName)) {
      errors.add('Некорректное имя');
    }

    final lastName = json['last_name']?.toString().trim() ?? '';
    if (lastName.isEmpty || !ValidationUtils.isValidName(lastName)) {
      errors.add('Некорректная фамилия');
    }

    final avatarUrl = json['avatar_url']?.toString().trim();
    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      errors.add('Некорректный URL аватара');
    }

    final bio = json['bio']?.toString().trim();
    if (bio != null && bio.length > 500) {
      errors.add('Биография не должна превышать 500 символов');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }

    return CreateProfileDto(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }

  Map<String, dynamic> toEntityData() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'sum_co2': 0,
      'saved_money': 0.0,
      'count_buy': 0,
    };
  }
}
