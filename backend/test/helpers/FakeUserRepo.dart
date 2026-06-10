import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/enums/UserRole.dart';
import 'package:postgres/postgres.dart';

/// Fake-репозиторий пользователей для юнит-тестов.
class FakeUserRepository extends UserRepository {
  final Map<int, User> _byId = {};
  final Map<String, User> _byUsername = {};
  final Map<String, User> _byEmail = {};
  final Map<String, User> _byNumber = {};
  final Map<int, User> _byTelegramId = {};
  final Map<String, User> _byYandexId = {};
  final Map<String, User> _byVkId = {};

  FakeUserRepository() : super(PostgreSQLConnection('test', 5432, 'test'));

  void seed(User user) {
    _byId[user.id] = user;
    _byUsername[user.username] = user;
    if (user.email != null) _byEmail[user.email!] = user;
    if (user.number != null) _byNumber[user.number!] = user;
    if (user.telegramId != null) _byTelegramId[user.telegramId!] = user;
    if (user.yandexId != null) _byYandexId[user.yandexId!] = user;
    if (user.vkId != null) _byVkId[user.vkId!] = user;
  }

  @override
  Future<User?> findById(int id) async => _byId[id];

  @override
  Future<User?> findByUsername(String username) async => _byUsername[username];

  @override
  Future<User?> findByEmail(String email) async => _byEmail[email];

  @override
  Future<User?> findByNumber(String number) async => _byNumber[number];

  @override
  Future<User?> findByTelegramId(int telegramId) async => _byTelegramId[telegramId];

  @override
  Future<User?> findByYandexId(String yandexId) async => _byYandexId[yandexId];

  @override
  Future<User?> findByVkId(String vkId) async => _byVkId[vkId];

  @override
  Future<User?> authenticate(String identifier, String password) async =>
      _byUsername[identifier] ?? _byNumber[identifier];

  @override
  Future<User> createUser(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final user = User(
      id: _byId.length + 1,
      username: data['username'] as String,
      password: data['password'] as String? ?? 'hash',
      number: data['number'] as String?,
      email: data['email'] as String?,
      createdAt: now,
      role: UserRole.user,
    );
    seed(user);
    return user;
  }

  @override
  Future<User> createOAuthUser({
    required String baseUsername,
    String? email,
    String? yandexId,
    String? vkId,
    String? firstName,
    String? lastName,
  }) async {
    var username = baseUsername;
    var suffix = 1;
    while (_byUsername.containsKey(username)) {
      username = '${baseUsername}_$suffix';
      suffix++;
    }
    final user = User(
      id: _byId.length + 1,
      username: username,
      email: email,
      yandexId: yandexId,
      vkId: vkId,
      firstName: firstName,
      lastName: lastName,
      createdAt: DateTime.now(),
      role: UserRole.user,
    );
    seed(user);
    return user;
  }

  @override
  Future<User> createTelegramUser({
    required int telegramId,
    String? telegramUsername,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final user = User(
      id: _byId.length + 1,
      username: 'tg_$telegramId',
      telegramId: telegramId,
      telegramUsername: telegramUsername,
      firstName: firstName,
      lastName: lastName,
      number: phone,
      createdAt: DateTime.now(),
      role: UserRole.user,
    );
    seed(user);
    return user;
  }

  @override
  Future<User> updatePhone(int userId, String phone) async {
    final user = _byId[userId];
    if (user == null) throw Exception('Пользователь не найден');
    final updated = User(
      id: user.id,
      username: user.username,
      password: user.passwordHash,
      email: user.email,
      number: phone,
      telegramId: user.telegramId,
      telegramUsername: user.telegramUsername,
      firstName: user.firstName,
      lastName: user.lastName,
      yandexId: user.yandexId,
      vkId: user.vkId,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      role: user.role,
    );
    seed(updated);
    return updated;
  }

  @override
  Future<void> setPassword(int userId, String password) async {
    final user = _byId[userId];
    if (user == null) throw Exception('Пользователь не найден');
    // FakeRepo: просто пересеваем с паролем
    final updated = User(
      id: user.id,
      username: user.username,
      password: password,
      email: user.email,
      number: user.number,
      telegramId: user.telegramId,
      telegramUsername: user.telegramUsername,
      firstName: user.firstName,
      lastName: user.lastName,
      yandexId: user.yandexId,
      vkId: user.vkId,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      role: user.role,
    );
    seed(updated);
  }

  @override
  Future<void> linkYandexId(int userId, String yandexId) async {
    final user = _byId[userId];
    if (user == null) throw Exception('Пользователь не найден');
    final updated = User(
      id: user.id,
      username: user.username,
      password: user.passwordHash,
      email: user.email,
      number: user.number,
      telegramId: user.telegramId,
      telegramUsername: user.telegramUsername,
      firstName: user.firstName,
      lastName: user.lastName,
      yandexId: yandexId,
      vkId: user.vkId,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      role: user.role,
    );
    seed(updated);
  }

  @override
  Future<void> linkVkId(int userId, String vkId) async {
    final user = _byId[userId];
    if (user == null) throw Exception('Пользователь не найден');
    final updated = User(
      id: user.id,
      username: user.username,
      password: user.passwordHash,
      email: user.email,
      number: user.number,
      telegramId: user.telegramId,
      telegramUsername: user.telegramUsername,
      firstName: user.firstName,
      lastName: user.lastName,
      yandexId: user.yandexId,
      vkId: vkId,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      role: user.role,
    );
    seed(updated);
  }
}

/// Создаёт минимально валидный User для тестов.
User makeUser({
  int id = 1,
  String username = 'testuser',
  String? email = 'test@example.com',
  String? number = '+79001234567',
  UserRole role = UserRole.user,
}) {
  return User(
    id: id,
    username: username,
    password: 'hashed_password',
    number: number,
    email: email,
    createdAt: DateTime(2024, 1, 1),
    role: role,
  );
}
