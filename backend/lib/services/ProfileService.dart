import '../model/entities/Profile.dart';
import '../repositories/ProfileRepository.dart';

class ProfileService {
  final ProfileRepository _profileRepository;

  ProfileService(this._profileRepository);

  Future<Profile> getProfileById(int id) async {
    final result = await _profileRepository.queryOne(
      'SELECT * FROM profiles WHERE id = @id',
      params: {'id': id},
    );
    if (result == null) {
      throw Exception('Профиль не найден');
    }
    return Profile.fromJson(result);
  }

  Future<List<Profile>> getAllProfiles() async {
    final results = await _profileRepository.query('SELECT * FROM profiles');
    return results.map((map) => Profile.fromJson(map)).toList();
  }

  Future<Profile> updateProfile(int id, Map<String, dynamic> data) async {
    _validateProfileData(data);
    final result = await _profileRepository.queryOne(
      '''
      UPDATE profiles 
      SET 
        saved_money = COALESCE(@savedMoney, saved_money),
        count_buy = COALESCE(@countBuy, count_buy),
        sum_co2 = COALESCE(@sumCO2, sum_co2),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
      RETURNING *
      ''',
      params: {
        'id': id,
        ...data,
      },
    );

    if (result == null) {
      throw Exception('Профиль не найден');
    }
    return Profile.fromJson(result);
  }

  Future<void> deleteProfile(int id) async {
    final result = await _profileRepository.queryOne(
      'DELETE FROM profiles WHERE id = @id RETURNING id',
      params: {'id': id},
    );
    if (result == null) {
      throw Exception('Профиль не найден');
    }
  }

  Future<Profile> createProfile(Map<String, dynamic> data) async {
    _validateProfileData(data);
    final result = await _profileRepository.queryOne(
      '''
      INSERT INTO profiles (
        user_id, saved_money, count_buy, sum_co2, created_at, updated_at
      ) VALUES (
        @userId, @savedMoney, @countBuy, @sumCO2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      ) RETURNING *
      ''',
      params: data,
    );
    if (result == null) {
      throw Exception('Ошибка создания профиля');
    }
    return Profile.fromJson(result);
  }

  void _validateProfileData(Map<String, dynamic> data) {
    if (data['savedMoney'] != null && (data['savedMoney'] as double) < 0) {
      throw Exception('Сохранённые средства не могут быть отрицательными');
    }
    if (data['countBuy'] != null && (data['countBuy'] as int) < 0) {
      throw Exception('Количество покупок не может быть отрицательным');
    }
    if (data['sumCO2'] != null && (data['sumCO2'] as int) < 0) {
      throw Exception('Сумма CO2 не может быть отрицательной');
    }
  }
}