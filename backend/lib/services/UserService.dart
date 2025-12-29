import '../repositories/UserRepository.dart';
import '../model/entities/User.dart';
import 'package:shared/enums/UserRole.dart';
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
        throw Exception('Пользователь не найден');
      }
      
      final user = User.fromJson(result);
      
      // Сохраняем в кеш
      await _cacheService.set(cacheKey, user, ttl: CacheTTL.user);
      
      return user;
    } catch (e) {
      print('Ошибка получения пользователя: $e');
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
      print('Ошибка получения списка пользователей: $e');
      rethrow;
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    try {
      print('Обновление пользователя с ID: $id');
      SafeLoggingUtils.logData('Данные для обновления', data);
      
      // Валидация данных обновления
      final validationErrors = UserValidationUtils.validateUserUpdateData(data);
      if (validationErrors.isNotEmpty) {
        final errorMessages = validationErrors.values.join(', ');
        throw Exception('Ошибки валидации: $errorMessages');
      }
      
      if (data['password'] != null) {
        data['password'] = AuthUtils.hashPassword(data['password']);
      }

      print('Вызов метода update в UserRepository');
      final result = await _userRepository.update(id, data);
      print('Результат обновления: $result');

      if (result == null) {
        throw Exception('Пользователь не найден');
      }
      
      // Инвалидируем кеш
      await _invalidateUserCache(id);
      
      return result;
    } catch (e) {
      print('Ошибка обновления пользователя: $e');
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
      print('Ошибка удаления пользователя: $e');
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
      print('Ошибка обновления баланса: $e');
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
      print('Ошибка добавления в избранное: $e');
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
      print('Ошибка удаления из избранного: $e');
      rethrow;
    }
  }

  void _validateUserData(Map<String, dynamic> data) {
    if (data['username'] != null && (data['username'] as String).isEmpty) {
      throw Exception('Имя пользователя не может быть пустым');
    }
    if (data['email'] != null && (data['email'] as String).isEmpty) {
      throw Exception('Email не может быть пустым');
    }
    if (data['number'] != null && (data['number'] as String).isEmpty) {
      throw Exception('Номер телефона не может быть пустым');
    }
    if (data['role'] != null) {
      try {
        UserRole.values.firstWhere(
          (role) => role.name.toLowerCase() == (data['role'] as String).toLowerCase(),
        );
      } catch (e) {
        throw Exception('Некорректная роль пользователя');
      }
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
      print('Ошибка инвалидации кеша пользователя: $e');
      // Не пробрасываем ошибку, так как это не критично
    }
  }
}
