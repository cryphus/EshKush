import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PartnerSettingsRepository.dart';
import 'package:backend/model/entities/PartnerSettings.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PartnerSettingsRepository repo;
  late int partnerId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PartnerSettingsRepository(conn);
    final userId = await TestFixtures.createUser(conn);
    partnerId = await TestFixtures.createPartner(conn, userId);
  });

  setUp(() async => TestDb.truncate(conn, ['partner_settings']));

  tearDownAll(() async => TestDb.close());

  PartnerSettings _settings({String color = '#FFFFFF'}) => PartnerSettings(
        id: 0,
        partnerId: partnerId,
        brandingColor: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт настройки с id > 0', () async {
      final result = await repo.create(_settings());
      expect(result.id, greaterThan(0));
      expect(result.partnerId, partnerId);
      expect(result.brandingColor, '#FFFFFF');
    });

    test('сохраняет цвет бренда', () async {
      final result = await repo.create(_settings(color: '#FF0000'));
      expect(result.brandingColor, '#FF0000');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает настройки по id', () async {
      final created = await repo.create(_settings());
      final found = await repo.findById(created.id);
      expect(found?.brandingColor, '#FFFFFF');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByPartnerId ───────────────────────────────────────────────────────
  group('findByPartnerId', () {
    test('возвращает настройки по partnerId', () async {
      await repo.create(_settings(color: '#00FF00'));
      final found = await repo.findByPartnerId(partnerId);
      expect(found?.brandingColor, '#00FF00');
    });

    test('возвращает null если настройки не существуют', () async {
      expect(await repo.findByPartnerId(999999), isNull);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет brandingColor', () async {
      final created = await repo.create(_settings());
      final updated = await repo.update(created.id, {'branding_color': '#0000FF'});
      expect(updated.brandingColor, '#0000FF');
    });

    test('бросает Exception если настройки не найдены', () async {
      expect(
        () => repo.update(999999, {'branding_color': '#000'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет настройки', () async {
      final created = await repo.create(_settings());
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если настройки не найдены', () async {
      expect(() => repo.delete(999999), throwsA(isA<Exception>()));
    });
  });

  // ── findAll ───────────────────────────────────────────────────────────────
  group('findAll', () {
    test('возвращает пустой список', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('возвращает созданные настройки', () async {
      await repo.create(_settings());
      expect((await repo.findAll()).length, 1);
    });
  });
}
