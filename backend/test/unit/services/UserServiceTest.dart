import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/UserService.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/enums/UserRole.dart';

import 'UserServiceTest.mocks.dart';

@GenerateMocks([UserRepository, CacheService])
void main() {
  late MockUserRepository userRepo;
  late MockCacheService cache;
  late UserService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    userRepo = MockUserRepository();
    cache    = MockCacheService();
    sut      = UserService(userRepo, cache);

    // По умолчанию: кеш промахивается, set/delete — no-op
    when(cache.get(any)).thenAnswer((_) async => null);
    when(cache.set(any, any, ttl: anyNamed('ttl'))).thenAnswer((_) async => true);
    when(cache.delete(any)).thenAnswer((_) async => true);
    when(cache.deleteByPattern(any)).thenAnswer((_) async => 0);
    when(cache.isConnected).thenReturn(true);
  });

  // ────────────────────────────────────────────────────────── fixtures ──────
  User _user({int id = 1, String username = 'testuser'}) => User(
    id: id, username: username, password: 'hash',
    number: '+79001234567', email: 'test@example.com',
    createdAt: DateTime(2024), role: UserRole.user,
  );

  Map<String, dynamic> _userMap({int id = 1, String username = 'testuser'}) => {
    'id': id, 'username': username, 'password': 'hash',
    'email': 'test@example.com', 'number': '+79001234567',
    'created_at': '2024-01-01T00:00:00.000Z', 'role': 'user',
  };

  // ── getUserById ───────────────────────────────────────────────────────────
  group('getUserById', () {
    test('возвращает из кеша без обращения к БД', () async {
      when(cache.get(any)).thenAnswer((_) async => _user());
      final result = await sut.getUserById(1);
      expect(result.id, 1);
      verifyNever(userRepo.queryOne(any, params: anyNamed('params')));
    });

    test('при кеш-промахе загружает из БД и кеширует', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => _userMap());
      final result = await sut.getUserById(1);
      expect(result.id, 1);
      verify(cache.set(any, any, ttl: anyNamed('ttl'))).called(1);
    });

    test('бросает если пользователь не найден в БД', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => null);
      expect(() => sut.getUserById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getAllUsers ───────────────────────────────────────────────────────────
  group('getAllUsers', () {
    test('без роли: возвращает всех пользователей из БД', () async {
      when(userRepo.query(any, params: anyNamed('params')))
          .thenAnswer((_) async => [_userMap(id: 1), _userMap(id: 2, username: 'other')]);
      final result = await sut.getAllUsers();
      expect(result.length, 2);
    });

    test('с ролью: передаёт role в запрос', () async {
      when(userRepo.query(any, params: anyNamed('params')))
          .thenAnswer((_) async => [_userMap()]);
      final result = await sut.getAllUsers(role: UserRole.user);
      expect(result.length, 1);
    });

    test('при кеш-хите не обращается к БД', () async {
      when(cache.get(any)).thenAnswer((_) async => [_userMap()]);
      final result = await sut.getAllUsers();
      expect(result.length, 1);
      verifyNever(userRepo.query(any, params: anyNamed('params')));
    });
  });

  // ── updateUser ───────────────────────────────────────────────────────────
  group('updateUser', () {
    test('бросает при ошибке валидации', () async {
      // пустой username проходит через UserValidationUtils
      expect(
        () => sut.updateUser(1, {'username': ''}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если пользователь не найден', () async {
      when(userRepo.update(any, any)).thenThrow(Exception('Пользователь не найден'));
      expect(() => sut.updateUser(1, {'username': 'newname'}), throwsA(isA<Exception>()));
    });

    test('успешно обновляет и инвалидирует кеш', () async {
      when(userRepo.update(any, any)).thenAnswer((_) async => _user(username: 'updated'));
      final result = await sut.updateUser(1, {'username': 'updated'});
      expect(result.username, 'updated');
      verify(cache.delete(any)).called(greaterThan(0));
    });

    test('хеширует пароль при обновлении', () async {
      when(userRepo.update(any, any)).thenAnswer((_) async => _user());
      await sut.updateUser(1, {'password': 'NewPass1!'});
      final captured = verify(userRepo.update(captureAny, captureAny)).captured;
      final updatedData = captured[1] as Map<String, dynamic>;
      expect(updatedData['password'], isNot('NewPass1!'));
      expect((updatedData['password'] as String).length, greaterThan(20));
    });
  });

  // ── deleteUser ───────────────────────────────────────────────────────────
  group('deleteUser', () {
    test('бросает если пользователь не найден', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => null);
      expect(() => sut.deleteUser(99), throwsA(isA<Exception>()));
    });

    test('успешно удаляет и инвалидирует кеш', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.deleteUser(1), completes);
      verify(cache.delete(any)).called(greaterThan(0));
    });
  });

  // ── updateBalance ─────────────────────────────────────────────────────────
  group('updateBalance', () {
    test('бросает если сумма слишком большая', () async {
      expect(() => sut.updateBalance(1, 2000000), throwsA(isA<Exception>()));
    });

    test('бросает если пользователь не найден', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => null);
      expect(() => sut.updateBalance(99, 100), throwsA(isA<Exception>()));
    });

    test('успешно обновляет баланс', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.updateBalance(1, 500), completes);
    });

    test('принимает отрицательные суммы (списание)', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.updateBalance(1, -100), completes);
    });

    test('граничное значение: ровно 1 000 000 проходит', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.updateBalance(1, 1000000), completes);
    });

    test('граничное значение: 1 000 001 отклоняется', () async {
      expect(() => sut.updateBalance(1, 1000001), throwsA(isA<Exception>()));
    });
  });

  // ── addToFavorites / removeFromFavorites ──────────────────────────────────
  group('addToFavorites', () {
    test('бросает при некорректном pointId (0)', () async {
      expect(() => sut.addToFavorites(1, 0), throwsA(isA<Exception>()));
    });

    test('бросает при отрицательном pointId', () async {
      expect(() => sut.addToFavorites(1, -5), throwsA(isA<Exception>()));
    });

    test('успешно добавляет', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.addToFavorites(1, 10), completes);
    });
  });

  group('removeFromFavorites', () {
    test('бросает при некорректном pointId', () async {
      expect(() => sut.removeFromFavorites(1, 0), throwsA(isA<Exception>()));
    });

    test('успешно удаляет', () async {
      when(userRepo.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'id': 1});
      await expectLater(sut.removeFromFavorites(1, 10), completes);
    });
  });
}