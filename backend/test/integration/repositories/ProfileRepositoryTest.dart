import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ProfileRepository.dart';
import 'package:backend/model/entities/Profile.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late ProfileRepository repo;
  late int userId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ProfileRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['profiles']));

  tearDownAll(() async => TestDb.close());

  Profile _profile({
    String firstName = 'Иван',
    String lastName = 'Иванов',
  }) =>
      Profile(
        id: 0,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        avatarUrl: '',
        bio: '',
        sumCO2: 0,
        savedMoney: 0.0,
        countBuy: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт профиль с id > 0', () async {
      final result = await repo.create(_profile());
      expect(result.id, greaterThan(0));
      expect(result.userId, userId);
      expect(result.firstName, 'Иван');
    });

    test('сохраняет lastName', () async {
      final result = await repo.create(_profile(lastName: 'Петров'));
      expect(result.lastName, 'Петров');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает профиль по id', () async {
      final created = await repo.create(_profile());
      final found = await repo.findById(created.id);
      expect(found?.firstName, 'Иван');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает профиль по userId', () async {
      await repo.create(_profile(firstName: 'Алексей'));
      final found = await repo.findByUserId(userId);
      expect(found?.firstName, 'Алексей');
    });

    test('возвращает null если профиль не существует', () async {
      expect(await repo.findByUserId(999999), isNull);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет firstName и lastName', () async {
      final created = await repo.create(_profile());
      final toUpdate = Profile(
        id: created.id,
        userId: created.userId,
        firstName: 'Обновлённый',
        lastName: 'Пользователь',
        avatarUrl: created.avatarUrl,
        bio: created.bio,
        sumCO2: created.sumCO2,
        savedMoney: created.savedMoney,
        countBuy: created.countBuy,
        createdAt: created.createdAt,
        updatedAt: DateTime.now(),
      );
      final updated = await repo.update(toUpdate);
      expect(updated.firstName, 'Обновлённый');
      expect(updated.lastName, 'Пользователь');
    });
  });
}
