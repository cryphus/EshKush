import '../repositories/UserRepository.dart';
import '../utils/auth_utils.dart';
import '../model/entities/User.dart';
import '../model/enums/UserRole.dart';

class AuthService {
  final UserRepository _userRepository;
  
  AuthService(this._userRepository);

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      if (data['username'] == null || data['password'] == null) {
        throw Exception('Требуются username и password');
      }

      final existing = await _userRepository.findByUsername(data['username']);
      if (existing != null) {
        throw Exception('Пользователь уже существует');
      }

      final user = await _userRepository.create(User(
        id: 0,
        username: data['username'],
        password: AuthUtils.hashPassword(data['password']),
        number: data['number'] ?? '+7',
        email: data['email'] ?? '${data['username']}@example.com',
        role: UserRole.values[data['role'] as int? ?? UserRole.user.index],
        sumCO2: 0,
        money: 0,
        favoriteIds: [],
        purchases: [],
      ));

      return {
        'token': AuthUtils.generateToken(user.id, user.role.toString()),
        'user': {
          'id': user.id,
          'username': user.username,
          'role': user.role.toString(),
          'email': user.email,
        }
      };
    } catch (e) {
      print('Ошибка регистрации: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Требуются username и password');
    }

    final user = await _userRepository.authenticate(
      username,
      AuthUtils.hashPassword(password),
    );
    
    if (user == null) {
      throw Exception('Неверный логин или пароль');
    }

    return {
      'token': AuthUtils.generateToken(user.id, user.role.toString()),
      'user': {
        'id': user.id,
        'username': user.username,
        'role': user.role.toString(),
        'email': user.email,
      }
    };
  }
} 