import '../model/entities/User.dart';
import 'BaseRepository.dart';

class UserRepository extends BaseRepository {
  UserRepository(super.connection);

  Future<User?> findByUsername(String username) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE username = @username',
        params: {'username': username},
      );
      return result == null ? null : User.fromMap(result);
    } catch (e) {
      print('Ошибка поиска пользователя: $e');
      rethrow;
    }
  }

  Future<User> create(User user) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO users (
          username, password, number, email, role,
          sum_co2, money, favorite_ids, purchases
        ) VALUES (
          @username, @password, @number, @email, @role::user_role,
          @sumCO2, @money, @favoriteIds, @purchases
        ) RETURNING *
        ''',
        params: {
          'username': user.username,
          'password': user.password,
          'number': user.number,
          'email': user.email,
          'role': user.role.name.toLowerCase(),
          'sumCO2': user.sumCO2,
          'money': user.money,
          'favoriteIds': user.favoriteIds,
          'purchases': user.purchases,
        },
      );
      return User.fromMap(result!);
    } catch (e) {
      print('Ошибка создания пользователя: $e');
      rethrow;
    }
  }

  Future<User?> authenticate(String username, String password) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE username = @username AND password = @password',
        params: {
          'username': username,
          'password': password,
        },
      );
      return result == null ? null : User.fromMap(result);
    } catch (e) {
      print('Ошибка аутентификации: $e');
      rethrow;
    }
  }
} 