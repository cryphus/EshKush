import '../repositories/UserRepository.dart';
import '../utils/AuthUtils.dart';
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

      final String roleStr = (data['role'] as String).toLowerCase();
      UserRole role = UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == roleStr,
        orElse: () => UserRole.user,
      );

      final user = await _userRepository.create(User(
        id: 0,
        username: data['username'],
        password: data['password'],
        number: data['phone'] ?? '+7',
        email: data['email'] ?? '${data['username']}@example.com',
        created_at: DateTime.now(),
        role: role,
      ));

      final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());

      return {
        ...tokens,
        'user': {
          'id': user.id,
          'username': user.username,
          'role': user.role.name.toLowerCase(),
          'email': user.email,
          'number': user.number,
          'created_at': user.created_at.toIso8601String(),
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

    final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());

    return {
      ...tokens,
      'user': {
        'id': user.id,
        'username': user.username,
        'role': user.role.name.toLowerCase(),
        'email': user.email,
      }
    };
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final payload = AuthUtils.verifyToken(refreshToken, isRefreshToken: true);
      final userId = payload['id'] as int;
      
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());

      return {
        ...tokens,
        'user': {
          'id': user.id,
          'username': user.username,
          'role': user.role.name.toLowerCase(),
          'email': user.email,
        }
      };
    } catch (e) {
      throw Exception('Недействительный refresh token');
    }
  }
} 