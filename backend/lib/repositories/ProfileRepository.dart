import '../model/entities/Profile.dart';
import 'BaseRepository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(super.connection);

  Future<Profile?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          user_id,
          COALESCE(first_name, '') AS first_name,
          COALESCE(last_name, '') AS last_name,
          COALESCE(avatar_url, '') AS avatar_url,
          COALESCE(bio, '') AS bio,
          COALESCE(sum_co2, 0) AS sum_co2,
          COALESCE(saved_money, 0.0) AS saved_money,
          COALESCE(count_buy, 0) AS count_buy,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS updated_at
        FROM profiles
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : Profile.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile?> findByUserId(int userId) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          user_id,
          COALESCE(first_name, '') AS first_name,
          COALESCE(last_name, '') AS last_name,
          COALESCE(avatar_url, '') AS avatar_url,
          COALESCE(bio, '') AS bio,
          COALESCE(sum_co2, 0) AS sum_co2,
          COALESCE(saved_money, 0.0) AS saved_money,
          COALESCE(count_buy, 0) AS count_buy,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS updated_at
        FROM profiles
        WHERE user_id = @userId
        ORDER BY id DESC
        LIMIT 1
        ''',
        params: {'userId': userId},
      );
      if (result == null) {
        return null;
      }

      return Profile.fromJson(result);
    } catch (e) {
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
          user_id, first_name, last_name, avatar_url, bio, sum_co2, saved_money, count_buy, created_at, updated_at
        ) VALUES (
          @userId, @firstName, @lastName, @avatarUrl, @bio, @sumCO2, @savedMoney, @countBuy, @createdAt, @updatedAt
        ) RETURNING *
        ''',
        params: {
          'userId': profile.userId,
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'avatarUrl': profile.avatarUrl,
          'bio': profile.bio,
          'sumCO2': profile.sumCO2,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
          'createdAt': profile.createdAt,
          'updatedAt': profile.updatedAt,
        },
      );
      return Profile.fromJson(result!);
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile> update(Profile profile) async {
    try {
      final result = await queryOne(
        '''
        UPDATE profiles 
        SET 
          first_name = @firstName,
          last_name = @lastName,
          avatar_url = @avatarUrl,
          bio = @bio,
          sum_co2 = @sumCO2,
          saved_money = @savedMoney,
          count_buy = @countBuy,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': profile.id,
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'avatarUrl': profile.avatarUrl,
          'bio': profile.bio,
          'sumCO2': profile.sumCO2,
          'savedMoney': profile.savedMoney,
          'countBuy': profile.countBuy,
        },
      );
      return Profile.fromJson(result!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await queryOne(
        'DELETE FROM profiles WHERE user_id = @userId RETURNING user_id',
        params: {'userId': id},
      );
    } catch (e) {
      rethrow;
    }
  }
}
