import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../utils/AppException.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/ValidationUtils.dart';
import '../model/entities/UserSessions.dart';
import '../model/enums/UserRole.dart';

class AuthService {
  final UserRepository _userRepository;
  final UserSessionRepository _sessionRepository;
  final Map<String, int> _failedLoginAttempts = <String, int>{};
  final Map<String, DateTime> _lockedUntil = <String, DateTime>{};

  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 15);

  AuthService(this._userRepository, this._sessionRepository);

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data, {
    String userAgent = 'unknown',
    String ipAddress = 'unknown',
    String? deviceId,
  }) async {
    SafeLoggingUtils.logData('AuthService.register - входящие данные', data);

    final validationErrors =
        UserValidationUtils.validateUserRegistrationData(data);
    if (validationErrors.isNotEmpty) {
      final errorMessages = validationErrors.values.join(', ');
      throw ValidationException('Ошибки валидации: $errorMessages');
    }

    final existing = await _userRepository.findByUsername(data['username']);
    if (existing != null) {
      throw ConflictException('Пользователь уже существует');
    }

    data = {...data, 'role': 'user'};
    final roleStr = 'user';
    if (!UserValidationUtils.isValidUserRole(roleStr)) {
      throw ValidationException(
        'Некорректная роль пользователя. Доступные роли: '
        '${UserRole.values.map((r) => r.name).join(', ')}',
      );
    }

    final role = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == roleStr,
    );

    SafeLoggingUtils.logDataWithContext(
      'AuthService.register - создание пользователя',
      data,
      context: {'role': role.name},
    );

    final user = await _userRepository.createUser(data);
    final bundle =
        AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
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
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String userAgent = 'unknown',
    String ipAddress = 'unknown',
    String? deviceId,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw const BadRequestException('Требуются username и password');
    }

    final loginKey = _buildLoginKey(username, ipAddress);
    _ensureNotLocked(loginKey);

    final user = await _userRepository.authenticate(username, password);
    if (user == null) {
      _registerFailedAttempt(loginKey);
      throw const UnauthorizedException('Неверный логин или пароль');
    }
    _resetFailedAttempts(loginKey);

    final bundle =
        AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
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
        throw const UnauthorizedException('Отсутствует jti в refresh токене');
      }

      final userId = payload['id'] as int;
      final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
      final session =
          await _sessionRepository.findActiveByRefreshJtiHash(refreshJtiHash);
      if (session == null || session.userId != userId) {
        throw const UnauthorizedException(
          'Refresh токен отозван или недействителен',
        );
      }

      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw const UnauthorizedException('Пользователь не найден');
      }

      final bundle =
          AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
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
      if (e is AppException) rethrow;
      throw const UnauthorizedException('Недействительный refresh token');
    }
  }

  String _buildLoginKey(String username, String ipAddress) =>
      '${username.trim().toLowerCase()}|$ipAddress';

  void _ensureNotLocked(String key) {
    final lockedUntil = _lockedUntil[key];
    if (lockedUntil == null) return;

    if (DateTime.now().isAfter(lockedUntil)) {
      _lockedUntil.remove(key);
      _failedLoginAttempts.remove(key);
      return;
    }

    throw TooManyRequestsException(
      'Слишком много неудачных попыток входа. Повторите после ${lockedUntil.toIso8601String()}',
    );
  }

  void _registerFailedAttempt(String key) {
    final attempts = (_failedLoginAttempts[key] ?? 0) + 1;
    if (attempts >= _maxFailedAttempts) {
      _failedLoginAttempts.remove(key);
      _lockedUntil[key] = DateTime.now().add(_lockDuration);
      return;
    }
    _failedLoginAttempts[key] = attempts;
  }

  void _resetFailedAttempts(String key) {
    _failedLoginAttempts.remove(key);
    _lockedUntil.remove(key);
  }
}
