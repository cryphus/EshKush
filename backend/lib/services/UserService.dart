import '../repositories/UserRepository.dart';
import '../model/entities/User.dart';
import '../model/enums/UserRole.dart';
import '../utils/AuthUtils.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<User> getUserById(int id) async {
    try {
      final result = await _userRepository.queryOne(
        'SELECT * FROM users WHERE id = @id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Пользователь не найден');
      }
      return User.fromJson(result);
    } catch (e) {
      print('Ошибка получения пользователя: $e');
      rethrow;
    }
  }

  Future<List<User>> getAllUsers({UserRole? role}) async {
    try {
      final query = role != null 
          ? 'SELECT * FROM users WHERE role = @role::user_role'
          : 'SELECT * FROM users';
      final Map<String, dynamic> params = role != null 
          ? {'role': role.name.toLowerCase()} 
          : {};
      
      final results = await _userRepository.query(query, params: params);
      return results.map((map) => User.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения списка пользователей: $e');
      rethrow;
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    try {
      _validateUserData(data);
      
      if (data['email'] != null && (data['email'] as String).isNotEmpty) {
        if (!RegExp(r'^.+@.+\..+').hasMatch(data['email'])) {
          throw Exception('Некорректный email');
        }
      }
      if (data['number'] != null && (data['number'] as String).isNotEmpty) {
        if (!RegExp(r'^\+\d{11,14}').hasMatch(data['number'])) {
          throw Exception('Некорректный номер телефона');
        }
      }
      if (data['password'] != null) {
        data['password'] = AuthUtils.hashPassword(data['password']);
      }

      final result = await _userRepository.queryOne(
        '''
        UPDATE users 
        SET 
          username = COALESCE(@username, username),
          password = COALESCE(@password, password),
          email = COALESCE(@email, email),
          number = COALESCE(@number, number),
          role = COALESCE(@role::user_role, role)
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': id,
          ...data,
        },
      );

      if (result == null) {
        throw Exception('Пользователь не найден');
      }
      return User.fromJson(result);
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
}
