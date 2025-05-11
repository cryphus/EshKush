import '../model/entities/Profile.dart';
import 'BaseRepository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(super.connection);

  Future<Profile?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM profiles WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : Profile.fromJson(result);
    } catch (e) {
      print('Ошибка поиска профиля по ID: $e');
      rethrow;
    }
  }

  Future<Profile?> findByUserId(int userId) async {
    try {
      final result = await queryOne(
        'SELECT * FROM profiles WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return result == null ? null : Profile.fromJson(result);
    } catch (e) {
      print('Ошибка поиска профиля по ID пользователя: $e');
      rethrow;
    }
  }

  Future<Profile> create(Profile profile) async {
    try {
      if (profile.userId <= 0) {
        throw ArgumentError('Некорректный ID пользователя');
      }
      final result = await queryOne(
        '''
        INSERT INTO profiles (
          user_id, saved_money, count_buy, sum_co2, created_at, updated_at
        ) VALUES (
          @userId, @savedMoney, @countBuy, @sumCO2, @createdAt, @updatedAt
        ) RETURNING *
        ''',
        params: {
          'userId': profile.userId,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'sumCO2': profile.sumCO2,
          'createdAt': profile.createdAt,
          'updatedAt': profile.updatedAt,
        },
      );
      return Profile.fromJson(result!);
    } catch (e) {
      print('Ошибка создания профиля: $e');
      rethrow;
    }
  }

  Future<Profile> update(Profile profile) async {
    try {
      final result = await queryOne(
        '''
        UPDATE profiles 
        SET 
          saved_money = @savedMoney,
          count_buy = @countBuy,
          sum_co2 = @sumCO2,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': profile.id,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'sumCO2': profile.sumCO2,
        },
      );
      return Profile.fromJson(result!);
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await queryOne(
        'DELETE FROM profiles WHERE id = @id RETURNING id',
        params: {'id': id},
      );
    } catch (e) {
      print('Ошибка удаления профиля: $e');
      rethrow;
    }
  }
}