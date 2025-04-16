import '../repositories/UserRepository.dart';
import '../model/entities/User.dart';
import '../utils/AuthUtils.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<User> getUserById(int id) async {
    final result = await _userRepository.queryOne(
      'SELECT * FROM users WHERE id = @id',
      params: {'id': id},
    );
    if (result == null) {
      throw Exception('Пользователь не найден');
    }
    return User.fromJson(result);
  }

  Future<List<User>> getAllUsers() async {
    final results = await _userRepository.query('SELECT * FROM users');
    return results.map((map) => User.fromJson(map)).toList();
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
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
        number = COALESCE(@number, number)
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
  }

  Future<void> deleteUser(int id) async {
    final result = await _userRepository.queryOne(
      'DELETE FROM users WHERE id = @id RETURNING id',
      params: {'id': id},
    );
    if (result == null) {
      throw Exception('Пользователь не найден');
    }
  }

  Future<void> updateBalance(int userId, int amount) async {
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
  }

  Future<void> addToFavorites(int userId, int pointId) async {
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
  }

  Future<void> removeFromFavorites(int userId, int pointId) async {
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
  }
}
