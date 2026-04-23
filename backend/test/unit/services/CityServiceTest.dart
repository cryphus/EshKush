import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/CityService.dart';
import 'package:backend/repositories/CityRepository.dart';
import 'package:backend/model/entities/City.dart';

import 'CityServiceTest.mocks.dart';

@GenerateMocks([CityRepository])
void main() {
  late MockCityRepository repo;
  late CityService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockCityRepository();
    sut  = CityService(repo);
  });

  City _city({int id = 1, String name = 'Moscow'}) =>
      City(id: id, name: name, createdAt: DateTime(2024));

  group('getById', () {
    test('возвращает город', () async {
      when(repo.findById(1)).thenAnswer((_) async => _city());
      expect((await sut.getById(1))?.name, 'Moscow');
    });
    test('возвращает null если не найден', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getById(99), isNull);
    });
  });

  group('getAll', () {
    test('возвращает список городов', () async {
      when(repo.findAll()).thenAnswer((_) async => [_city(id: 1), _city(id: 2, name: 'SPb')]);
      final result = await sut.getAll();
      expect(result.length, 2);
    });
  });

  group('create', () {
    test('делегирует в репозиторий', () async {
      final city = _city();
      when(repo.create(city)).thenAnswer((_) async => city);
      final result = await sut.create(city);
      expect(result.name, 'Moscow');
    });
  });

  group('update', () {
    test('делегирует в репозиторий', () async {
      final city = _city(name: 'Updated');
      when(repo.update(city)).thenAnswer((_) async => city);
      final result = await sut.update(city);
      expect(result.name, 'Updated');
    });
  });

  group('delete', () {
    test('делегирует в репозиторий', () async {
      when(repo.delete(1)).thenAnswer((_) async {});
      await expectLater(sut.delete(1), completes);
      verify(repo.delete(1)).called(1);
    });
  });
}
