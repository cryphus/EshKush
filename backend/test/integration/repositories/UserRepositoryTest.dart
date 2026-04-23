import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/model/enums/UserRole.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late UserRepository repo;

  /// Данные для создания тестового пользователя.
  Map<String, dynamic> _userData({
    String username = 'testuser',
    String email = 'test@example.com',
    String number = '+79001234567',
    String password = 'TestPass1!',
  }) =>
      {
        'username': username,
        'email': email,
        'number': number,
        'password': password,
        'password_confirm': password,
        'role': 'user',
      };

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = UserRepository(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['user_sessions', 'user_favorites', 'users']));

  tearDownAll(() async => TestDb.close());

  // ── createUser ────────────────────────────────────────────────────────────
  group('createUser', () {
    test('создаёт пользователя и возвращает с id > 0', () async {
      final user = await repo.createUser(_userData());
      expect(user.id, greaterThan(0));
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
    });

    test('пароль хешируется — не хранится открытым', () async {
      final user = await repo.createUser(_userData(password: 'PlainPass1!'));
      expect(user.passwordHash, isNot('PlainPass1!'));
      expect(user.passwordHash!.length, greaterThan(20));
    });

    test('роль по умолчанию — user', () async {
      final user = await repo.createUser(_userData());
      expect(user.role, UserRole.user);
    });

    test('бросает при дублирующемся username', () async {
      await repo.createUser(_userData(username: 'alice', email: 'a@e.com', number: '+79001234561'));
      expect(
        () => repo.createUser(_userData(username: 'alice', email: 'b@e.com', number: '+79001234562')),
        throwsA(anything),
      );
    });

    test('бросает при дублирующемся email', () async {
      await repo.createUser(_userData(username: 'user1', email: 'dup@e.com', number: '+79001234561'));
      expect(
        () => repo.createUser(_userData(username: 'user2', email: 'dup@e.com', number: '+79001234562')),
        throwsA(anything),
      );
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает пользователя по id', () async {
      final created = await repo.createUser(_userData());
      final found = await repo.findById(created.id);
      expect(found?.username, 'testuser');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByUsername ────────────────────────────────────────────────────────
  group('findByUsername', () {
    test('находит пользователя по username', () async {
      await repo.createUser(_userData(username: 'bob', email: 'bob@e.com'));
      final found = await repo.findByUsername('bob');
      expect(found?.username, 'bob');
    });

    test('возвращает null если username не существует', () async {
      expect(await repo.findByUsername('nobody'), isNull);
    });
  });

  // ── findByEmail ───────────────────────────────────────────────────────────
  group('findByEmail', () {
    test('находит пользователя по email', () async {
      await repo.createUser(_userData(email: 'carol@example.com'));
      final found = await repo.findByEmail('carol@example.com');
      expect(found?.email, 'carol@example.com');
    });

    test('возвращает null если email не существует', () async {
      expect(await repo.findByEmail('ghost@example.com'), isNull);
    });
  });

  // ── findAll ───────────────────────────────────────────────────────────────
  group('findAll', () {
    test('возвращает пустой список', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('возвращает созданных пользователей', () async {
      await repo.createUser(_userData(username: 'usr1', email: 'u1@e.com', number: '+79001111111'));
      await repo.createUser(_userData(username: 'usr2', email: 'u2@e.com', number: '+79002222222'));
      expect((await repo.findAll()).length, 2);
    });

    test('limit ограничивает количество', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.createUser(_userData(
          username: 'user$i',
          email: 'u$i@e.com',
          number: '+7900000000$i',
        ));
      }
      final result = await repo.findAll(limit: 3);
      expect(result.length, 3);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет username', () async {
      final created = await repo.createUser(_userData());
      final updated = await repo.update(created.id, {'username': 'updated_name'});
      expect(updated.username, 'updated_name');
    });

    test('бросает Exception если пользователь не найден', () async {
      expect(
        () => repo.update(999999, {'username': 'ghost'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── authenticate ──────────────────────────────────────────────────────────
  group('authenticate', () {
    test('возвращает пользователя при верном пароле', () async {
      await repo.createUser(_userData(username: 'dave', email: 'dave@e.com', password: 'Dave@Pass1!'));
      final result = await repo.authenticate('dave', 'Dave@Pass1!');
      expect(result?.username, 'dave');
    });

    test('возвращает null при неверном пароле', () async {
      await repo.createUser(_userData(username: 'eve', email: 'eve@e.com', password: 'Eve@Pass1!'));
      final result = await repo.authenticate('eve', 'WrongPassword');
      expect(result, isNull);
    });

    test('возвращает null если пользователь не найден', () async {
      expect(await repo.authenticate('unknown', 'pass'), isNull);
    });

    test('аутентификация по номеру телефона', () async {
      await repo.createUser(_userData(username: 'frank', email: 'frank@e.com', number: '+79005551234', password: 'Frank@1!'));
      final result = await repo.authenticate('+79005551234', 'Frank@1!');
      expect(result?.username, 'frank');
    });
  });

  // ── createTelegramUser ────────────────────────────────────────────────────
  group('createTelegramUser', () {
    test('создаёт пользователя без пароля и email', () async {
      final user = await repo.createTelegramUser(
        telegramId: 123456789,
        telegramUsername: 'tg_testuser',
        firstName: 'Тест',
        lastName: 'Юзер',
      );
      expect(user.id, greaterThan(0));
      expect(user.username, 'tg_123456789');
      expect(user.telegramId, 123456789);
      expect(user.telegramUsername, 'tg_testuser');
      expect(user.passwordHash, isNull);
      expect(user.email, isNull);
    });

    test('findByTelegramId находит созданного пользователя', () async {
      await repo.createTelegramUser(telegramId: 987654321);
      final found = await repo.findByTelegramId(987654321);
      expect(found?.telegramId, 987654321);
    });

    test('findByTelegramId возвращает null если нет', () async {
      expect(await repo.findByTelegramId(0), isNull);
    });

    test('updatePhone устанавливает номер Telegram-пользователя', () async {
      final user = await repo.createTelegramUser(telegramId: 111222333);
      final updated = await repo.updatePhone(user.id, '+79001112233');
      expect(updated.number, '+79001112233');
    });

    test('setPassword устанавливает пароль Telegram-пользователя', () async {
      final user = await repo.createTelegramUser(telegramId: 444555666);
      await repo.setPassword(user.id, 'NewPass@1234');
      final found = await repo.findById(user.id);
      expect(found?.passwordHash, isNotNull);
      expect(found?.passwordHash, isNot('NewPass@1234'));
    });
  });

  // ── createOAuthUser ───────────────────────────────────────────────────────
  group('createOAuthUser', () {
    test('создаёт пользователя с yandexId', () async {
      final user = await repo.createOAuthUser(
        baseUsername: 'yandex_user',
        email: 'ya@example.com',
        yandexId: 'yandex_uid_abc',
        firstName: 'Яндекс',
      );
      expect(user.id, greaterThan(0));
      expect(user.yandexId, 'yandex_uid_abc');
      expect(user.email, 'ya@example.com');
    });

    test('findByYandexId находит пользователя', () async {
      await repo.createOAuthUser(baseUsername: 'yauser2', yandexId: 'ya_uid_xyz');
      final found = await repo.findByYandexId('ya_uid_xyz');
      expect(found?.yandexId, 'ya_uid_xyz');
    });

    test('создаёт пользователя с vkId', () async {
      final user = await repo.createOAuthUser(
        baseUsername: 'vk_user',
        vkId: 'vk_uid_123',
      );
      expect(user.vkId, 'vk_uid_123');
    });

    test('findByVkId находит пользователя', () async {
      await repo.createOAuthUser(baseUsername: 'vkuser2', vkId: 'vk_uid_456');
      final found = await repo.findByVkId('vk_uid_456');
      expect(found?.vkId, 'vk_uid_456');
    });

    test('генерирует уникальный username при конфликте', () async {
      await repo.createOAuthUser(baseUsername: 'dupname', email: 'a@a.com');
      final second = await repo.createOAuthUser(baseUsername: 'dupname', email: 'b@b.com', yandexId: 'ya_dup');
      expect(second.username, isNot('dupname'));
      expect(second.username, contains('dupname'));
    });
  });

  // ── linkYandexId / linkVkId ────────────────────────────────────────────────
  group('linkOAuthId', () {
    test('linkYandexId устанавливает yandex_id существующему пользователю', () async {
      final user = await repo.createUser(_userData(username: 'linkya', email: 'linkya@e.com'));
      await repo.linkYandexId(user.id, 'linked_ya_id');
      final found = await repo.findByYandexId('linked_ya_id');
      expect(found?.id, user.id);
    });

    test('linkVkId устанавливает vk_id существующему пользователю', () async {
      final user = await repo.createUser(_userData(username: 'linkvk', email: 'linkvk@e.com'));
      await repo.linkVkId(user.id, 'linked_vk_id');
      final found = await repo.findByVkId('linked_vk_id');
      expect(found?.id, user.id);
    });
  });
}
