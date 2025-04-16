import '../model/entities/User.dart';
import 'BaseRepository.dart';

class UserRepository extends BaseRepository {
  UserRepository(super.connection);

  Future<User?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : User.fromJson(result);
    } catch (e) {
      print('Ошибка поиска пользователя по ID: $e');
      rethrow;
    }
  }

  Future<User?> findByUsername(String username) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE username = @username',
        params: {'username': username},
      );
      return result == null ? null : User.fromJson(result);
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
          username, password, number, email, role, created_at
        ) VALUES (
          @username, @password, @number, @email, @role::user_role, @created_at
        ) RETURNING *
        ''',
        params: {
          'username': user.username,
          'password': user.passwordHash,
          'number': user.number,
          'email': user.email,
          'role': user.role.name.toLowerCase(),
          'created_at': user.created_at,
        },
      );
      return User.fromJson(result!);
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
      return result == null ? null : User.fromJson(result);
    } catch (e) {
      print('Ошибка аутентификации: $e');
      rethrow;
    }
  }

  Future<User?> findByEmail(String email) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE email = @email',
        params: {'email': email},
      );
      return result == null ? null : User.fromJson(result);
    } catch (e) {
      print('Ошибка поиска пользователя по email: $e');
      rethrow;
    }
  }
} 