import 'package:postgres/postgres.dart';
import '../model/entities/User.dart';
import '../utils/AuthUtils.dart';

class UserRepository {
  final PostgreSQLConnection _connection;

  UserRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      if (results.isEmpty) return null;
      return results.first.values.first;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

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
      print('Ошибка поиска пользователя по имени: $e');
      rethrow;
    }
  }

  Future<User> create(User user) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES (@username, @password, @email, @number, @role::user_role, @created_at)
        RETURNING *
        ''',
        params: {
          'username': user.username,
          'password': user.passwordHash,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.created_at,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания пользователя');
      }
      return User.fromJson(result);
    } catch (e) {
      print('Ошибка создания пользователя: $e');
      rethrow;
    }
  }

  Future<User?> authenticate(String username, String passwordHash) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE username = @username AND password = @password',
        params: {
          'username': username,
          'password': passwordHash,
        },
      );
      return result == null ? null : User.fromJson(result);
    } catch (e) {
      print('Ошибка аутентификации: $e');
      rethrow;
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      _validateUserData(data);
      
      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role)
        VALUES (@username, @password, @email, @number, @role::user_role)
        RETURNING *
        ''',
        params: {
          'username': data['username'],
          'password': AuthUtils.hashPassword(data['password']),
          'email': data['email'],
          'number': data['number'],
          'role': data['role'] ?? 'user',
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания пользователя');
      }

      return User.fromJson(result);
    } catch (e) {
      print('Ошибка создания пользователя: $e');
      rethrow;
    }
  }

  Future<User?> findByEmail(String email) async {
    try {
      if (!RegExp(r'^.+@.+\..+$').hasMatch(email)) {
        throw Exception('Некорректный email');
      }

      return await queryOne(
        'SELECT * FROM users WHERE email = @email',
        params: {'email': email},
      ).then((result) => result != null ? User.fromJson(result) : null);
    } catch (e) {
      print('Ошибка поиска пользователя по email: $e');
      rethrow;
    }
  }

  Future<User?> findByNumber(String number) async {
    try {
      if (!RegExp(r'^\+\d{11,14}').hasMatch(number)) {
        throw Exception('Некорректный номер телефона');
      }

      return await queryOne(
        'SELECT * FROM users WHERE number = @number',
        params: {'number': number},
      ).then((result) => result != null ? User.fromJson(result) : null);
    } catch (e) {
      print('Ошибка поиска пользователя по номеру: $e');
      rethrow;
    }
  }

  Future<List<int>> getFavoritePoints(int userId) async {
    try {
      final result = await queryOne(
        'SELECT favorite_ids FROM users WHERE id = @id',
        params: {'id': userId},
      );
      
      if (result == null) {
        throw Exception('Пользователь не найден');
      }

      final List<dynamic> favoriteIds = result['favorite_ids'] ?? [];
      return favoriteIds.map((id) => id as int).toList();
    } catch (e) {
      print('Ошибка получения избранных точек: $e');
      rethrow;
    }
  }

  Future<void> addFavoritePoint(int userId, int pointId) async {
    try {
      if (pointId <= 0) {
        throw Exception('Некорректный идентификатор точки');
      }

      await queryOne(
        '''
        UPDATE users 
        SET favorite_ids = array_append(favorite_ids, @pointId)
        WHERE id = @userId AND NOT @pointId = ANY(favorite_ids)
        ''',
        params: {
          'userId': userId,
          'pointId': pointId,
        },
      );
    } catch (e) {
      print('Ошибка добавления точки в избранное: $e');
      rethrow;
    }
  }

  Future<void> removeFavoritePoint(int userId, int pointId) async {
    try {
      if (pointId <= 0) {
        throw Exception('Некорректный идентификатор точки');
      }

      await queryOne(
        '''
        UPDATE users 
        SET favorite_ids = array_remove(favorite_ids, @pointId)
        WHERE id = @userId
        ''',
        params: {
          'userId': userId,
          'pointId': pointId,
        },
      );
    } catch (e) {
      print('Ошибка удаления точки из избранного: $e');
      rethrow;
    }
  }

  void _validateUserData(Map<String, dynamic> data) {
    if (data['username'] == null || (data['username'] as String).isEmpty) {
      throw Exception('Имя пользователя не может быть пустым');
    }
    if (data['password'] == null || (data['password'] as String).isEmpty) {
      throw Exception('Пароль не может быть пустым');
    }
    if (data['email'] == null || !RegExp(r'^.+@.+\..+$').hasMatch(data['email'])) {
      throw Exception('Некорректный email');
    }
    if (data['number'] == null || !RegExp(r'^\+\d{11,14}').hasMatch(data['number'])) {
      throw Exception('Некорректный номер телефона');
    }
  }
} 