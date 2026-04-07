import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import '../model/entities/UserSessions.dart';
import '../model/enums/UserRole.dart';

class AuthService {
  final UserRepository _userRepository;
  final UserSessionRepository _sessionRepository;
  
  AuthService(this._userRepository, this._sessionRepository);

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data, {
    String userAgent = 'unknown',
    String ipAddress = 'unknown',
    String? deviceId,
  }) async {
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

      final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
      final refreshJti = bundle['refresh_jti'] as String;
      final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

      await _sessionRepository.create(
        UserSessions(
          id: 0,
          userId: user.id,
          createdAt: DateTime.now(),
          expiresAt: refreshExpiresAt,
          lastActive: DateTime.now(),
          userAgent: userAgent,
          ipAddress: ipAddress,
          deviceId: deviceId,
          token: bundle['access_token'] as String,
          refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
        ),
      );

      return {
        'access_token': bundle['access_token'],
        'refresh_token': bundle['refresh_token'],
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String userAgent = 'unknown',
    String ipAddress = 'unknown',
    String? deviceId,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Требуются username и password');
    }

    final user = await _userRepository.authenticate(username, password);
    
    if (user == null) {
      throw Exception('Неверный логин или пароль');
    }

    final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
    final refreshJti = bundle['refresh_jti'] as String;
    final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

    await _sessionRepository.create(
      UserSessions(
        id: 0,
        userId: user.id,
        createdAt: DateTime.now(),
        expiresAt: refreshExpiresAt,
        lastActive: DateTime.now(),
        userAgent: userAgent,
        ipAddress: ipAddress,
        deviceId: deviceId,
        token: bundle['access_token'] as String,
        refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
      ),
    );

    return {
      'access_token': bundle['access_token'],
      'refresh_token': bundle['refresh_token'],
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
      final refreshJti = payload['jti']?.toString() ?? '';
      if (refreshJti.isEmpty) {
        throw Exception('Отсутствует jti в refresh токене');
      }
      final userId = payload['id'] as int;
      
      final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
      final session = await _sessionRepository.findActiveByRefreshJtiHash(refreshJtiHash);
      if (session == null || session.userId != userId) {
        throw Exception('Refresh токен отозван или недействителен');
      }

      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
      final newRefreshJti = bundle['refresh_jti'] as String;
      final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

      session.refreshJtiHash = AuthUtils.hashRefreshJti(newRefreshJti);
      session.expiresAt = refreshExpiresAt;
      session.lastActive = DateTime.now();
      await _sessionRepository.update(session);

      return {
        'access_token': bundle['access_token'],
        'refresh_token': bundle['refresh_token'],
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