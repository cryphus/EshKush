import '../repositories/UserRepository.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import '../model/entities/User.dart';
import '../model/enums/UserRole.dart';

class AuthService {
  final UserRepository _userRepository;
  
  AuthService(this._userRepository);

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('AuthService.register - входные данные', data);
      
      // Валидация данных регистрации
      final validationErrors = UserValidationUtils.validateUserRegistrationData(data);
      if (validationErrors.isNotEmpty) {
        final errorMessages = validationErrors.values.join(', ');
        throw Exception('Ошибки валидации: $errorMessages');
      }

      final existing = await _userRepository.findByUsername(data['username']);
      if (existing != null) {
        throw Exception('Пользователь уже существует');
      }

      // Строгая валидация роли
      final String roleStr = (data['role'] as String? ?? 'user').toLowerCase();
      if (!UserValidationUtils.isValidUserRole(roleStr)) {
        throw Exception('Некорректная роль пользователя. Доступные роли: ${UserRole.values.map((r) => r.name).join(', ')}');
      }
      
      UserRole role = UserRole.values.firstWhere(
        (r) => r.name.toLowerCase() == roleStr,
      );

      SafeLoggingUtils.logDataWithContext(
        'AuthService.register - создание пользователя',
        data,
        context: {'role': role.name},
      );

      final user = await _userRepository.createUser(data);

      final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());

      return {
        ...tokens,
        'user': {
          'id': user.id,
          'username': user.username,
          'role': user.role.name.toLowerCase(),
          'email': user.email,
          'phoneNumber': user.number,
          'createdAt': user.createdAt.toIso8601String(),
          'updatedAt': user.updatedAt?.toIso8601String(),
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

    final user = await _userRepository.authenticate(username, password);
    
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