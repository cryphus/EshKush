import 'package:postgres/postgres.dart';
import '../model/entities/User.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import 'BaseRepository.dart';
import '../utils/AppException.dart';

class UserRepository extends BaseRepository {
  UserRepository(PostgreSQLConnection connection) : super(connection);

  /// Р В РІР‚СћР В РўвЂР В РЎвЂР В Р вЂ¦Р РЋРІР‚в„–Р В РІвЂћвЂ“ Р РЋР С“Р В РЎвЂ”Р В РЎвЂР РЋР С“Р В РЎвЂўР В РЎвЂќ Р В РЎвЂќР В РЎвЂўР В Р’В»Р В РЎвЂўР В Р вЂ¦Р В РЎвЂўР В РЎвЂќ users, Р В РЎвЂќР В РЎвЂўР РЋРІР‚С™Р В РЎвЂўР РЋР вЂљР РЋРІР‚в„–Р В РІвЂћвЂ“ Р В РўвЂР В РЎвЂўР В Р’В»Р В Р’В¶Р В Р’ВµР В Р вЂ¦ Р В Р вЂ Р В РЎвЂўР В Р’В·Р В Р вЂ Р РЋР вЂљР В Р’В°Р РЋРІР‚В°Р В Р’В°Р РЋРІР‚С™Р РЋР Р‰Р РЋР С“Р РЋР РЏ Р В Р вЂ Р В РЎвЂў Р В Р вЂ Р РЋР С“Р В Р’ВµР РЋРІР‚В¦ SELECT.
  /// Р В РІР‚СњР РЋРЎвЂњР В Р’В±Р В Р’В»Р В РЎвЂР РЋР вЂљР РЋРЎвЂњР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В Р вЂ  `fromJson`, Р В РЎвЂ”Р В РЎвЂўР РЋР РЉР РЋРІР‚С™Р В РЎвЂўР В РЎВР РЋРЎвЂњ Р РЋР С“Р В РЎвЂР В Р вЂ¦Р РЋРІР‚В¦Р РЋР вЂљР В РЎвЂўР В Р вЂ¦Р В РЎвЂР В Р’В·Р В РЎвЂР РЋР вЂљР РЋРЎвЂњР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В РЎвЂ”Р РЋР вЂљР В РЎвЂ Р РЋР вЂљР В Р’В°Р РЋР С“Р РЋРІвЂљВ¬Р В РЎвЂР РЋР вЂљР В Р’ВµР В Р вЂ¦Р В РЎвЂР В РЎвЂ Р РЋР С“Р РЋРІР‚В¦Р В Р’ВµР В РЎВР РЋРІР‚в„–.
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
    yandex_id,
    vk_id,
    role,
    to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
    CASE WHEN updated_at IS NOT NULL
         THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
         ELSE NULL END as updated_at
  ''';

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
        throw const InternalServerException();
      }
      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> authenticate(String identifier, String password) async {
    // Р В Р’ВР РЋРІР‚В°Р В Р’ВµР В РЎВ Р В РЎвЂ”Р В РЎвЂў username, Р В Р’ВµР РЋР С“Р В Р’В»Р В РЎвЂ Р В Р вЂ¦Р В Р’Вµ Р В Р вЂ¦Р В Р’В°Р В РІвЂћвЂ“Р В РўвЂР В Р’ВµР В Р вЂ¦Р В РЎвЂў Р Р†Р вЂљРІР‚Сњ Р В РЎвЂ”Р В РЎвЂў Р В Р вЂ¦Р В РЎвЂўР В РЎВР В Р’ВµР РЋР вЂљР РЋРЎвЂњ Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р В Р’ВµР РЋРІР‚С›Р В РЎвЂўР В Р вЂ¦Р В Р’В°
    var result = await queryOne(
      'SELECT $_userColumns FROM users WHERE username = @id',
      params: {'id': identifier},
    );

    result ??= await queryOne(
      'SELECT $_userColumns FROM users WHERE number = @id',
      params: {'id': identifier},
    );

    if (result == null) return null;

    final user = User.fromJson(result);
    final hash = user.passwordHash;
    if (hash == null || hash.isEmpty) return null;
    if (!AuthUtils.verifyPassword(password, hash)) return null;

    return user;
  }

  Future<User?> findByYandexId(String yandexId) async {
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE yandex_id = @yid',
      params: {'yid': yandexId},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User?> findByVkId(String vkId) async {
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE vk_id = @vid',
      params: {'vid': vkId},
    );
    return result == null ? null : User.fromJson(result);
  }

  /// Р В Р Р‹Р В РЎвЂўР В Р’В·Р В РўвЂР В Р’В°Р РЋРІР‚ВР РЋРІР‚С™ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР РЏ Р В Р вЂ¦Р В Р’В° Р В РЎвЂўР РЋР С“Р В Р вЂ¦Р В РЎвЂўР В Р вЂ Р В Р’Вµ Р В РўвЂР В Р’В°Р В Р вЂ¦Р В Р вЂ¦Р РЋРІР‚в„–Р РЋРІР‚В¦ OAuth Р В РЎвЂ”Р РЋР вЂљР В РЎвЂўР В Р вЂ Р В Р’В°Р В РІвЂћвЂ“Р В РўвЂР В Р’ВµР РЋР вЂљР В Р’В°.
  /// Username Р В РЎвЂ“Р В Р’ВµР В Р вЂ¦Р В Р’ВµР РЋР вЂљР В РЎвЂР РЋР вЂљР РЋРЎвЂњР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В РЎвЂР В Р’В· Р В РўвЂР В Р’В°Р В Р вЂ¦Р В Р вЂ¦Р РЋРІР‚в„–Р РЋРІР‚В¦ Р В РЎвЂ”Р РЋР вЂљР В РЎвЂўР В Р вЂ Р В Р’В°Р В РІвЂћвЂ“Р В РўвЂР В Р’ВµР РЋР вЂљР В Р’В°, Р В РЎвЂ”Р РЋР вЂљР В РЎвЂ Р В РЎвЂќР В РЎвЂўР В Р вЂ¦Р РЋРІР‚С›Р В Р’В»Р В РЎвЂР В РЎвЂќР РЋРІР‚С™Р В Р’Вµ Р В РўвЂР В РЎвЂўР В Р’В±Р В Р’В°Р В Р вЂ Р В Р’В»Р РЋР РЏР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р РЋР С“Р РЋРЎвЂњР РЋРІР‚С›Р РЋРІР‚С›Р В РЎвЂР В РЎвЂќР РЋР С“.
  Future<User> createOAuthUser({
    required String baseUsername,
    String? email,
    String? yandexId,
    String? vkId,
    String? firstName,
    String? lastName,
  }) async {
    var username = baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (username.length < 3) username = 'user_$username';
    if (username.length > 28) username = username.substring(0, 28);

    var finalUsername = username;
    var suffix = 1;
    while (await findByUsername(finalUsername) != null) {
      finalUsername = '${username}_$suffix';
      suffix++;
    }

    final result = await queryOne(
      '''
      INSERT INTO users (username, email, yandex_id, vk_id, first_name, last_name, role, created_at)
      VALUES (@username, @email, @yandex_id, @vk_id, @first_name, @last_name, 'user'::user_role, CURRENT_TIMESTAMP)
      RETURNING $_userColumns
      ''',
      params: {
        'username': finalUsername,
        'email': email,
        'yandex_id': yandexId,
        'vk_id': vkId,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    if (result == null) throw const InternalServerException();
    return User.fromJson(result);
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData(
          'Р В Р Р‹Р В РЎвЂўР В Р’В·Р В РўвЂР В Р’В°Р В Р вЂ¦Р В РЎвЂР В Р’Вµ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР РЏ Р РЋР С“ Р В РўвЂР В Р’В°Р В Р вЂ¦Р В Р вЂ¦Р РЋРІР‚в„–Р В РЎВР В РЎвЂ',
          data);
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
        throw const InternalServerException();
      }

      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  /// Р В Р Р‹Р В РЎвЂўР В Р’В·Р В РўвЂР В Р’В°Р РЋРІР‚ВР РЋРІР‚С™ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР РЏ Р В Р вЂ¦Р В Р’В° Р В РЎвЂўР РЋР С“Р В Р вЂ¦Р В РЎвЂўР В Р вЂ Р В Р’Вµ Р В РўвЂР В Р’В°Р В Р вЂ¦Р В Р вЂ¦Р РЋРІР‚в„–Р РЋРІР‚В¦ Р В РЎвЂР В Р’В· Р В РЎС›Р В Р’ВµР В Р’В»Р В Р’ВµР В РЎвЂ“Р РЋР вЂљР В Р’В°Р В РЎВР В Р’В°.
  /// Р В РЎСџР В Р’В°Р РЋР вЂљР В РЎвЂўР В Р’В»Р РЋР Р‰/email Р В Р вЂ¦Р В Р’Вµ Р В Р’В·Р В Р’В°Р В РўвЂР В Р’В°Р РЋР вЂ№Р РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р Р†Р вЂљРІР‚Сњ Р В РЎвЂР РЋРІР‚В¦ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР Р‰ Р В Р вЂ Р РЋРІР‚в„–Р РЋР С“Р РЋРІР‚С™Р В Р’В°Р В Р вЂ Р В РЎвЂР РЋРІР‚С™ Р В РЎвЂ”Р В РЎвЂўР В Р’В·Р В Р’В¶Р В Р’Вµ.
  /// Username Р В РЎвЂ“Р В Р’ВµР В Р вЂ¦Р В Р’ВµР РЋР вЂљР В РЎвЂР РЋР вЂљР РЋРЎвЂњР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В РЎвЂР В Р’В· telegram_id, Р РЋРІР‚РЋР РЋРІР‚С™Р В РЎвЂўР В Р’В±Р РЋРІР‚в„– Р РЋРЎвЂњР В РўвЂР В РЎвЂўР В Р вЂ Р В Р’В»Р В Р’ВµР РЋРІР‚С™Р В Р вЂ Р В РЎвЂўР РЋР вЂљР В РЎвЂР РЋРІР‚С™Р РЋР Р‰ NOT NULL + UNIQUE.
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
      throw const InternalServerException();
    }
    return User.fromJson(result);
  }

  /// Р В РЎвЂєР В Р’В±Р В Р вЂ¦Р В РЎвЂўР В Р вЂ Р В Р’В»Р РЋР РЏР В Р’ВµР РЋРІР‚С™ Р В Р вЂ¦Р В РЎвЂўР В РЎВР В Р’ВµР РЋР вЂљ Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р В Р’ВµР РЋРІР‚С›Р В РЎвЂўР В Р вЂ¦Р В Р’В° Р РЋР С“Р РЋРЎвЂњР РЋРІР‚В°Р В Р’ВµР РЋР С“Р РЋРІР‚С™Р В Р вЂ Р РЋРЎвЂњР РЋР вЂ№Р РЋРІР‚В°Р В Р’ВµР В РЎвЂ“Р В РЎвЂў Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР РЏ.
  /// Р В Р’ВР РЋР С“Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р РЋРЎвЂњР В Р’ВµР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В Р’В±Р В РЎвЂўР РЋРІР‚С™Р В РЎвЂўР В РЎВ Р В РЎвЂ”Р В РЎвЂўР РЋР С“Р В Р’В»Р В Р’Вµ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋРЎвЂњР РЋРІР‚РЋР В Р’ВµР В Р вЂ¦Р В РЎвЂР РЋР РЏ Р В РЎвЂќР В РЎвЂўР В Р вЂ¦Р РЋРІР‚С™Р В Р’В°Р В РЎвЂќР РЋРІР‚С™Р В Р’В° Р РЋРІР‚РЋР В Р’ВµР РЋР вЂљР В Р’ВµР В Р’В· request_contact.
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
      throw const NotFoundException();
    }
    return User.fromJson(result);
  }

  /// Р В Р в‚¬Р РЋР С“Р РЋРІР‚С™Р В Р’В°Р В Р вЂ¦Р В Р’В°Р В Р вЂ Р В Р’В»Р В РЎвЂР В Р вЂ Р В Р’В°Р В Р’ВµР РЋРІР‚С™ Р В РЎвЂ”Р В Р’В°Р РЋР вЂљР В РЎвЂўР В Р’В»Р РЋР Р‰ Р В РЎвЂ”Р В РЎвЂўР В Р’В»Р РЋР Р‰Р В Р’В·Р В РЎвЂўР В Р вЂ Р В Р’В°Р РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР РЏ (Р В РўвЂР В Р’В»Р РЋР РЏ Telegram-Р РЋР вЂ№Р В Р’В·Р В Р’ВµР РЋР вЂљР В РЎвЂўР В Р вЂ , Р В РЎвЂќР В РЎвЂўР РЋРІР‚С™Р В РЎвЂўР РЋР вЂљР РЋРІР‚в„–Р В Р’Вµ
  /// Р РЋРІР‚В¦Р В РЎвЂўР РЋРІР‚С™Р РЋР РЏР РЋРІР‚С™ Р В РўвЂР В РЎвЂўР В РЎвЂ”Р В РЎвЂўР В Р’В»Р В Р вЂ¦Р В РЎвЂР РЋРІР‚С™Р В Р’ВµР В Р’В»Р РЋР Р‰Р В Р вЂ¦Р В РЎвЂў Р В Р вЂ Р РЋРІР‚В¦Р В РЎвЂўР В РўвЂР В РЎвЂР РЋРІР‚С™Р РЋР Р‰ Р РЋРІР‚РЋР В Р’ВµР РЋР вЂљР В Р’ВµР В Р’В· Р В Р’В»Р В РЎвЂўР В РЎвЂ“Р В РЎвЂР В Р вЂ¦/Р В РЎвЂ”Р В Р’В°Р РЋР вЂљР В РЎвЂўР В Р’В»Р РЋР Р‰).
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

  Future<void> linkYandexId(int userId, String yandexId) async {
    await queryOne(
      'UPDATE users SET yandex_id = @yid, updated_at = CURRENT_TIMESTAMP WHERE id = @id RETURNING id',
      params: {'id': userId, 'yid': yandexId},
    );
  }

  Future<void> linkVkId(int userId, String vkId) async {
    await queryOne(
      'UPDATE users SET vk_id = @vid, updated_at = CURRENT_TIMESTAMP WHERE id = @id RETURNING id',
      params: {'id': userId, 'vid': vkId},
    );
  }

  Future<User?> findByEmail(String email) async {
    if (!UserValidationUtils.isValidEmail(email)) {
      throw const BadRequestException();
    }
    final result = await queryOne(
      'SELECT $_userColumns FROM users WHERE email = @email',
      params: {'email': email},
    );
    return result == null ? null : User.fromJson(result);
  }

  Future<User?> findByNumber(String number) async {
    if (!UserValidationUtils.isValidPhoneNumber(number)) {
      throw const BadRequestException();
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
        throw const NotFoundException();
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
        throw const BadRequestException();
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
        throw const BadRequestException();
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
    final validationErrors =
        UserValidationUtils.validateUserRegistrationData(data);
    if (validationErrors.isNotEmpty) {
      final errorMessages = validationErrors.values.join(', ');
      throw BadRequestException(errorMessages);
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
        throw const BadRequestException();
      }

      final updateQuery = '''
        UPDATE users
        SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING $_userColumns
      ''';

      final result = await queryOne(updateQuery, params: params);

      if (result == null) {
        throw const NotFoundException();
      }

      return User.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> findAll({int limit = 20, int offset = 0}) async {
    final normalizedLimit = limit.clamp(1, 50);
    final normalizedOffset = offset < 0 ? 0 : offset;
    final results = await query(
      '''
      SELECT $_userColumns
      FROM users
      ORDER BY id
      LIMIT @limit OFFSET @offset
      ''',
      params: {'limit': normalizedLimit, 'offset': normalizedOffset},
    );
    return results.map((map) => User.fromJson(map)).toList();
  }
}
