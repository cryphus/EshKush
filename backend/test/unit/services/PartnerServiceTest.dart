import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PartnerService.dart';
import 'package:backend/repositories/PartnerRepository.dart';
import 'package:backend/model/entities/Partner.dart';

import 'PartnerServiceTest.mocks.dart';

@GenerateMocks([PartnerRepository])
void main() {
  late MockPartnerRepository repo;
  late PartnerService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockPartnerRepository();
    sut  = PartnerService(repo);
  });

  Partner _partner({int id = 1, String name = 'TestPartner', double maxDiscount = 10.0}) =>
      Partner(
        id: id, userId: 1, name: name,
        maxDiscount: maxDiscount, createdAt: DateTime(2024),
      );

  // ── getPartner ─────────────────────────────────────────────────────────────
  group('getPartner', () {
    test('возвращает партнера по id', () async {
      when(repo.findById(1)).thenAnswer((_) async => _partner());
      final result = await sut.getPartner(1);
      expect(result?.id, 1);
    });

    test('возвращает null если партнер не найден', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getPartner(99), isNull);
    });
  });

  // ── getAllPartners ─────────────────────────────────────────────────────────
  group('getAllPartners', () {
    test('возвращает список партнеров', () async {
      when(repo.findAll()).thenAnswer((_) async => [_partner(id: 1), _partner(id: 2)]);
      final result = await sut.getAllPartners();
      expect(result.length, 2);
    });
  });

  // ── updatePartnerName ──────────────────────────────────────────────────────
  group('updatePartnerName', () {
    test('пустое имя — бросает ArgumentError', () {
      expect(() => sut.updatePartnerName(1, ''), throwsArgumentError);
    });

    test('корректное имя — делегирует в репозиторий', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _partner(name: 'New'));
      final result = await sut.updatePartnerName(1, 'New');
      expect(result.name, 'New');
    });
  });

  // ── updatePartnerMaxDiscount ───────────────────────────────────────────────
  group('updatePartnerMaxDiscount', () {
    test('скидка < 0 — бросает ArgumentError', () {
      expect(() => sut.updatePartnerMaxDiscount(1, -1), throwsArgumentError);
    });

    test('скидка > 100 — бросает ArgumentError', () {
      expect(() => sut.updatePartnerMaxDiscount(1, 101), throwsArgumentError);
    });

    test('скидка = 0 — допустима', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _partner(maxDiscount: 0));
      await expectLater(sut.updatePartnerMaxDiscount(1, 0), completes);
    });

    test('скидка = 100 — допустима', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _partner(maxDiscount: 100));
      await expectLater(sut.updatePartnerMaxDiscount(1, 100), completes);
    });

    test('корректная скидка — обновляет', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _partner(maxDiscount: 25));
      final result = await sut.updatePartnerMaxDiscount(1, 25);
      expect(result.maxDiscount, 25);
    });
  });

  // ── deletePartner ──────────────────────────────────────────────────────────
  group('deletePartner', () {
    test('делегирует в репозиторий', () async {
      when(repo.delete(1)).thenAnswer((_) async {});
      await expectLater(sut.deletePartner(1), completes);
      verify(repo.delete(1)).called(1);
    });
  });
}
