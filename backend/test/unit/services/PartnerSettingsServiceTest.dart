import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PartnerSettingsService.dart';
import 'package:backend/repositories/PartnerSettingsRepository.dart';
import 'package:backend/model/entities/PartnerSettings.dart';

import 'PartnerSettingsServiceTest.mocks.dart';

@GenerateMocks([PartnerSettingsRepository])
void main() {
  late MockPartnerSettingsRepository repo;
  late PartnerSettingsService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockPartnerSettingsRepository();
    sut  = PartnerSettingsService(repo);
  });

  PartnerSettings _settings({int id = 1, String color = '#FF5733'}) =>
      PartnerSettings(
        id: id, partnerId: 1, brandingColor: color,
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      );

  // ── updateBrandingColor ────────────────────────────────────────────────────
  group('updateBrandingColor', () {
    test('некорректный hex — бросает ArgumentError', () {
      expect(
        () => sut.updateBrandingColor(1, 'notacolor'),
        throwsArgumentError,
      );
    });

    test('hex без # — бросает ArgumentError', () {
      expect(() => sut.updateBrandingColor(1, 'FF5733'), throwsArgumentError);
    });

    test('валидный 6-символьный hex — проходит', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _settings(color: '#FF5733'));
      final result = await sut.updateBrandingColor(1, '#FF5733');
      expect(result.brandingColor, '#FF5733');
    });

    test('валидный 3-символьный hex — проходит', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _settings(color: '#F57'));
      await expectLater(sut.updateBrandingColor(1, '#F57'), completes);
    });

    test('hex в нижнем регистре — допустим', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _settings(color: '#ff5733'));
      await expectLater(sut.updateBrandingColor(1, '#ff5733'), completes);
    });
  });

  // ── updateSettings ─────────────────────────────────────────────────────────
  group('updateSettings', () {
    test('некорректный branding_color — бросает ArgumentError', () {
      expect(
        () => sut.updateSettings(1, {'branding_color': 'invalid'}),
        throwsArgumentError,
      );
    });

    test('без branding_color — не валидирует цвет', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _settings());
      await expectLater(sut.updateSettings(1, {'some_field': 'value'}), completes);
    });

    test('с валидным цветом — обновляет', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _settings(color: '#123456'));
      final result = await sut.updateSettings(1, {'branding_color': '#123456'});
      expect(result.id, 1);
    });
  });

  // ── getSettings ───────────────────────────────────────────────────────────
  group('getSettings', () {
    test('возвращает настройки', () async {
      when(repo.findById(1)).thenAnswer((_) async => _settings());
      final result = await sut.getSettings(1);
      expect(result?.id, 1);
    });

    test('возвращает null если не найдены', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getSettings(99), isNull);
    });
  });

  // ── createSettings ─────────────────────────────────────────────────────────
  group('createSettings', () {
    test('делегирует в репозиторий', () async {
      when(repo.create(any)).thenAnswer((_) async => _settings());
      final result = await sut.createSettings(1, '#FF5733');
      expect(result.partnerId, 1);
      verify(repo.create(any)).called(1);
    });
  });
}
