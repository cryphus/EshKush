import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/CityRepository.dart';
import 'package:backend/model/entities/City.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late CityRepository repo;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = CityRepository(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['cities']));

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт город и возвращает с присвоенным id', () async {
      final result = await repo.create(City(name: 'Москва'));
      expect(result.id, greaterThan(0));
      expect(result.name, 'Москва');
    });

    test('id инкрементируется при создании нескольких городов', () async {
      final a = await repo.create(City(name: 'А'));
      final b = await repo.create(City(name: 'Б'));
      expect(b.id, greaterThan(a.id!));
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает город по существующему id', () async {
      final created = await repo.create(City(name: 'Питер'));
      final found = await repo.findById(created.id!);
      expect(found?.name, 'Питер');
      expect(found?.id, created.id);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findAll ───────────────────────────────────────────────────────────────
  group('findAll', () {
    test('возвращает пустой список если таблица пустая', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('возвращает все созданные города', () async {
      await repo.create(City(name: 'Город1'));
      await repo.create(City(name: 'Город2'));
      final all = await repo.findAll();
      expect(all.length, 2);
    });

    test('результат отсортирован по имени', () async {
      await repo.create(City(name: 'Я'));
      await repo.create(City(name: 'А'));
      final all = await repo.findAll();
      expect(all.first.name, 'А');
      expect(all.last.name, 'Я');
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет имя и возвращает обновлённый город', () async {
      final created = await repo.create(City(name: 'Старое'));
      final updated = await repo.update(City(id: created.id, name: 'Новое'));
      expect(updated.name, 'Новое');
      expect(updated.id, created.id);
    });

    test('id не изменяется после обновления', () async {
      final created = await repo.create(City(name: 'X'));
      final updated = await repo.update(City(id: created.id, name: 'Y'));
      expect(updated.id, created.id);
    });

    test('бросает Exception если город не найден', () async {
      expect(
        () => repo.update(City(id: 999999, name: 'Ghost')),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет город — findById возвращает null', () async {
      final created = await repo.create(City(name: 'ToDelete'));
      await repo.delete(created.id!);
      expect(await repo.findById(created.id!), isNull);
    });

    test('удаление одного города не затрагивает остальные', () async {
      final a = await repo.create(City(name: 'А'));
      final b = await repo.create(City(name: 'Б'));
      await repo.delete(a.id!);
      expect(await repo.findById(b.id!), isNotNull);
    });

    test('бросает Exception если город не найден', () async {
      expect(
        () => repo.delete(999999),
        throwsA(isA<Exception>()),
      );
    });
  });
}
