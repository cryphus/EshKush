import '../repositories/UserRepository.dart';
import '../model/entities/User.dart';
import '../model/enums/UserRole.dart';
import '../utils/AppException.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import 'CacheService.dart';

class UserService {
  final UserRepository _userRepository;
  final CacheService _cacheService;

  UserService(this._userRepository, this._cacheService);

  Future<User> getUserById(int id) async {
    try {
      // Пытаемся получить из кеша
      final cacheKey = CacheKeys.user(id);
      final cachedUser = await _cacheService.get<User>(cacheKey);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Если нет в кеше, получаем из БД
      final result = await _userRepository.queryOne(
        'SELECT * FROM users WHERE id = @id',
        params: {'id': id},
      );
      if (result == null) {
        throw NotFoundException('Пользователь не найден');
      }

      final user = User.fromJson(result);
      
      // Сохраняем в кеш
      await _cacheService.set(cacheKey, user, ttl: CacheTTL.user);
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getAllUsers({UserRole? role}) async {
    try {
      // Определяем ключ кеша
      final cacheKey = role != null 
          ? CacheKeys.usersByRole(role.name.toLowerCase())
          : CacheKeys.allUsers();
      
      // Пытаемся получить из кеша
      final cachedData = await _cacheService.get<List>(cacheKey);
      if (cachedData != null) {
        // Конвертируем JSON обратно в List<User>
        return cachedData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
      }

      // Если нет в кеше, получаем из БД
      final query = role != null 
          ? 'SELECT * FROM users WHERE role = @role::user_role'
          : 'SELECT * FROM users';
      final Map<String, dynamic> params = role != null 
          ? {'role': role.name.toLowerCase()} 
          : {};
      
      final results = await _userRepository.query(query, params: params);
      final users = results.map((map) => User.fromJson(map)).toList();
      
      // Сохраняем в кеш
      await _cacheService.set(cacheKey, users, ttl: CacheTTL.user);
      
      return users;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('Данные для обновления', data);
      
      // Валидация данных обновления
      final validationErrors = UserValidationUtils.validateUserUpdateData(data);
      if (validationErrors.isNotEmpty) {
        final errorMessages = validationErrors.values.join(', ');
        throw Exception('Ошибки валидации: $errorMessages');
      }
      
      if (data.containsKey('password')) {
        final oldPassword = data.remove('old_password') as String?;
        if (oldPassword == null || oldPassword.isEmpty) {
          throw ValidationException('Для смены пароля необходим текущий пароль (old_password)');
        }
        final currentUser = await _userRepository.findById(id);
        if (currentUser == null) throw Exception('Пользователь не найден');
        if (currentUser.passwordHash == null || !AuthUtils.verifyPassword(oldPassword, currentUser.passwordHash!)) {
          throw ValidationException('Неверный текущий пароль');
        }
        data['password'] = AuthUtils.hashPassword(data['password'] as String);
      } else {
        data.remove('old_password');
      }

      if (data['username'] != null) {
        final existing = await _userRepository.findByUsername(data['username'] as String);
        if (existing != null && existing.id != id) {
          throw ValidationException('Имя пользователя уже занято');
        }
      }
      if (data['email'] != null) {
        final existing = await _userRepository.findByEmail(data['email'] as String);
        if (existing != null && existing.id != id) {
          throw ValidationException('Email уже используется');
        }
      }

      final result = await _userRepository.update(id, data);

      // Инвалидируем кеш
      await _invalidateUserCache(id);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final result = await _userRepository.queryOne(
        'DELETE FROM users WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Пользователь не найден');
      }
      
      // Инвалидируем кеш
      await _invalidateUserCache(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBalance(int userId, int amount) async {
    try {
      if (amount.abs() > 1000000) {
        throw Exception('Слишком большая сумма');
      }
      final result = await _userRepository.queryOne(
        '''
        UPDATE users 
        SET money = money + @amount
        WHERE id = @id
        RETURNING id
        ''',
        params: {
          'id': userId,
          'amount': amount,
        },
      );
      if (result == null) {
        throw Exception('Пользователь не найден');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addToFavorites(int userId, int pointId) async {
    try {
      if (pointId <= 0) {
        throw Exception('Некорректный идентификатор точки');
      }
      await _userRepository.queryOne(
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

  Future<void> removeFromFavorites(int userId, int pointId) async {
    try {
      if (pointId <= 0) {
        throw Exception('Некорректный идентификатор точки');
      }
      await _userRepository.queryOne(
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

  /// Инвалидация кеша пользователя
  Future<void> _invalidateUserCache(int userId) async {
    try {
      // Удаляем конкретного пользователя
      await _cacheService.delete(CacheKeys.user(userId));
      
      // Удаляем списки пользователей (они могут измениться)
      await _cacheService.delete(CacheKeys.allUsers());
      await _cacheService.deleteByPattern('users:role:*');
    } catch (e) {
      // Не пробрасываем ошибку, так как это не критично
    }
  }
}
