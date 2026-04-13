import 'package:postgres/postgres.dart';
import '../model/entities/User.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/PasswordFilter.dart';
import '../utils/ValidationUtils.dart';

class UserRepository {
  final PostgreSQLConnection _connection;

  UserRepository(this._connection);

  /// Единый список колонок users, который должен возвращаться во всех SELECT.
  /// Дублируется в `fromJson`, поэтому синхронизируется при расширении схемы.
  static const String _userColumns = '''
    id,
    username,
    password,
    email,
    number,
    telegram_id,
    telegram_username,
    first_name,
    last_name,
    role,
    to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
    CASE WHEN updated_at IS NOT NULL
         THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
         ELSE NULL END as updated_at
  ''';

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(
        query,
        substitutionValues: params,
        allowReuse: true,
      );

      if (results.isEmpty) return null;
      final result = results.first;
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
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE id = @id',
      params: {'id': id},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User?> findByUsername(String username) async {
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE username = @username',
      params: {'username': username},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User?> findByTelegramId(int telegramId) async {
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE telegram_id = @tid',
      params: {'tid': telegramId},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User> create(User user) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES (@username, @password, @email, @number, @role::user_role, @created_at)
        RETURNING $_userColumns
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
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE username = @username',
      params: {'username': username},
    );

    if (result == null) return null;

    final user = User.fromJson(result);
    final hash = user.passwordHash;
    if (hash == null || hash.isEmpty) return null;
    if (!AuthUtils.verifyPassword(password, hash)) {
      return null;
    }

    return user;
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('Создание пользователя с данными', data);
      _validateUserData(data);

      final result = await queryOne(
        '''
        INSERT INTO users (username, password, email, number, role, created_at)
        VALUES (@username, @password, @email, @number, @role::user_role, CURRENT_TIMESTAMP)
        RETURNING $_userColumns
        ''',
        params: {
          'username': data['username'],
          'password': AuthUtils.hashPassword(data['password']),
          'email': data['email'],
          'number': data['number'],
          'role': (data['role'] as String? ?? 'user').toLowerCase(),
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

  /// Создаёт пользователя на основе данных из Телеграма.
  /// Пароль/email не задаются — их пользователь выставит позже.
  /// Username генерируется из telegram_id, чтобы удовлетворить NOT NULL + UNIQUE.
  Future<User> createTelegramUser({
    required int telegramId,
    String? telegramUsername,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final generatedUsername = 'tg_$telegramId';

    final result = await queryOne(
      '''
      INSERT INTO users (
        username, telegram_id, telegram_username, first_name, last_name, number, role, created_at
      ) VALUES (
        @username, @tid, @tusername, @first, @last, @phone, 'user'::user_role, CURRENT_TIMESTAMP
      )
      RETURNING $_userColumns
      ''',
      params: {
        'username': generatedUsername,
        'tid': telegramId,
        'tusername': telegramUsername,
        'first': firstName,
        'last': lastName,
        'phone': phone,
      },
    );

    if (result == null) {
      throw Exception('Ошибка создания Telegram-пользователя');
    }
    return User.fromJson(result);
  }

  /// Обновляет номер телефона существующего пользователя.
  /// Используется ботом после получения контакта через request_contact.
  Future<User> updatePhone(int userId, String phone) async {
    final result = await queryOne(
      '''
      UPDATE users
      SET number = @phone, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
      RETURNING $_userColumns
      ''',
      params: {'id': userId, 'phone': phone},
    );
    if (result == null) {
      throw Exception('Пользователь не найден');
    }
    return User.fromJson(result);
  }

  /// Устанавливает пароль пользователя (для Telegram-юзеров, которые
  /// хотят дополнительно входить через логин/пароль).
  Future<void> setPassword(int userId, String password) async {
    await queryOne(
      '''
      UPDATE users
      SET password = @password, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
      RETURNING id
      ''',
      params: {
        'id': userId,
        'password': AuthUtils.hashPassword(password),
      },
    );
  }

  Future<User?> findByEmail(String email) async {
    if (!UserValidationUtils.isValidEmail(email)) {
      throw Exception('Некорректный email');
    }
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE email = @email',
      params: {'email': email},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User?> findByNumber(String number) async {
    if (!UserValidationUtils.isValidPhoneNumber(number)) {
      throw Exception('Некорректный номер телефона');
    }
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE number = @number',
      params: {'number': number},
    );
    return result == null ? null : User.fromJson(result);
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
    final validationErrors = UserValidationUtils.validateUserRegistrationData(data);
    if (validationErrors.isNotEmpty) {
      final errorMessages = validationErrors.values.join(', ');
      throw Exception('Ошибки валидации: $errorMessages');
    }
  }

  Future<User> update(int id, Map<String, dynamic> data) async {
    try {
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
        RETURNING $_userColumns
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
    final results = await query(
      '''
      SELECT $_userColumns
      FROM users
      ORDER BY id
      LIMIT @limit OFFSET @offset
      ''',
      params: {'limit': limit, 'offset': offset},
    );
    return results.map((map) => User.fromJson(map)).toList();
  }
}
