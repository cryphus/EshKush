import 'package:postgres/postgres.dart';
import '../model/entities/User.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/PasswordFilter.dart';
import '../utils/ValidationUtils.dart';

class UserRepository {
  final PostgreSQLConnection _connection;

  UserRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      // Не логируем параметры для безопасности
      
      final results = await _connection.mappedResultsQuery(
        query,
        substitutionValues: params,
        allowReuse: true,
      );
      
      if (results.isEmpty) return null;
      final result = results.first;
      // Не логируем результат для безопасности
      return result.values.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM users
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> findByUsername(String username) async {
    try {
      final result = await queryOne(
        'SELECT * FROM users WHERE username = @username',
        params: {'username': username},
      );
      if (result == null) {
        return null;
      }
      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> create(User user) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES (@username, @password, @email, @number, @role::user_role, @created_at)
        RETURNING 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL 
            THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL 
          END as updated_at
        ''',
        params: {
          'username': user.username,
          'password': user.passwordHash,
          'email': user.email,
          'number': user.number,
          'role': user.role.name.toLowerCase(),
          'created_at': user.createdAt,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания пользователя');
      }
      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> authenticate(String username, String password) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM users 
        WHERE username = @username
        ''',
        params: {'username': username},
      );
      
      if (result == null) return null;
      
      final user = User.fromJson(result);
      if (!AuthUtils.verifyPassword(password, user.passwordHash)) {
        return null;
      }
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('Создание пользователя с данными', data);
      _validateUserData(data);
      
      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES (@username, @password, @email, @number, @role::user_role, CURRENT_TIMESTAMP)
        RETURNING 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL 
            THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL 
          END as updated_at
        ''',
        params: {
          'username': data['username'],
          'password': AuthUtils.hashPassword(data['password']),
          'email': data['email'],
          'number': data['number'],
          'role': (data['role'] as String? ?? 'user').toLowerCase(),
        },
      );

      // Не логируем результат для безопасности

      if (result == null) {
        throw Exception('Ошибка создания пользователя');
      }

      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> findByEmail(String email) async {
    try {
      if (!UserValidationUtils.isValidEmail(email)) {
        throw Exception('Некорректный email');
      }

      return await queryOne(
        'SELECT * FROM users WHERE email = @email',
        params: {'email': email},
      ).then((result) => result != null ? User.fromJson(result) : null);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> findByNumber(String number) async {
    try {
      if (!UserValidationUtils.isValidPhoneNumber(number)) {
        throw Exception('Некорректный номер телефона');
      }

      return await queryOne(
        'SELECT * FROM users WHERE number = @number',
        params: {'number': number},
      ).then((result) => result != null ? User.fromJson(result) : null);
    } catch (e) {
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
      rethrow;
    }
  }

  void _validateUserData(Map<String, dynamic> data) {
    // Используем централизованную валидацию
    final validationErrors = UserValidationUtils.validateUserRegistrationData(data);
    if (validationErrors.isNotEmpty) {
      final errorMessages = validationErrors.values.join(', ');
      throw Exception('Ошибки валидации: $errorMessages');
    }
  }

  Future<User> update(int id, Map<String, dynamic> data) async {
    try {
      // Строим динамический SQL-запрос
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': id};

      if (data.containsKey('username')) {
        updateFields.add('username = COALESCE(@username, username)');
        params['username'] = data['username'];
      }
      if (data.containsKey('password')) {
        updateFields.add('password = COALESCE(@password, password)');
        params['password'] = data['password'];
      }
      if (data.containsKey('email')) {
        updateFields.add('email = COALESCE(@email, email)');
        params['email'] = data['email'];
      }
      if (data.containsKey('number')) {
        updateFields.add('number = COALESCE(@number, number)');
        params['number'] = data['number'];
      }
      if (data.containsKey('role')) {
        updateFields.add('role = COALESCE(@role::user_role, role)');
        params['role'] = data['role'];
      }

      if (updateFields.isEmpty) {
        throw Exception('Нет полей для обновления');
      }

      final updateQuery = '''
        UPDATE users 
        SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
      ''';


      final result = await queryOne(updateQuery, params: params);

      if (result == null) {
        throw Exception('Пользователь не найден');
      }

      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> findAll({int limit = 20, int offset = 0}) async {
    try {
      final results = await query(
        '''
        SELECT
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM users
        ORDER BY id
        LIMIT @limit OFFSET @offset
        ''',
        params: {'limit': limit, 'offset': offset},
      );
      return results.map((map) => User.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
} 