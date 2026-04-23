import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PartnerRepository.dart';
import 'package:backend/model/entities/Partner.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PartnerRepository repo;
  late int userId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PartnerRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['partners']));

  tearDownAll(() async => TestDb.close());

  Partner _partner({String name = 'ТестПартнёр'}) => Partner(
        id: 0,
        userId: userId,
        name: name,
        maxDiscount: 5.0,
        createdAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт партнёра с id > 0', () async {
      final result = await repo.create(_partner());
      expect(result.id, greaterThan(0));
      expect(result.name, 'ТестПартнёр');
      expect(result.userId, userId);
    });

    test('сохраняет maxDiscount', () async {
      final result = await repo.create(_partner());
      expect(result.maxDiscount, 5.0);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает партнёра по id', () async {
      final created = await repo.create(_partner(name: 'AlicePartner'));
      final found = await repo.findById(created.id);
      expect(found?.name, 'AlicePartner');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findAll ───────────────────────────────────────────────────────────────
  group('findAll', () {
    test('возвращает пустой список', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('возвращает всех созданных партнёров', () async {
      await repo.create(_partner(name: 'P1'));
      await repo.create(_partner(name: 'P2'));
      expect((await repo.findAll()).length, 2);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет name', () async {
      final created = await repo.create(_partner());
      final updated = await repo.update(created.id, {'name': 'НовоеИмя'});
      expect(updated.name, 'НовоеИмя');
    });

    test('id не меняется', () async {
      final created = await repo.create(_partner());
      final updated = await repo.update(created.id, {'name': 'ДругоеИмя'});
      expect(updated.id, created.id);
    });

    test('бросает Exception если партнёр не найден', () async {
      expect(
        () => repo.update(999999, {'name': 'ghost'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет партнёра', () async {
      final created = await repo.create(_partner());
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если партнёр не найден', () async {
      expect(() => repo.delete(999999), throwsA(isA<Exception>()));
    });
  });
}
