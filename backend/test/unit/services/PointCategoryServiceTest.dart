import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PointCategoryService.dart';
import 'package:backend/repositories/PointCategoryRepository.dart';
import 'package:backend/model/entities/PointCategory.dart';

import 'PointCategoryServiceTest.mocks.dart';

@GenerateMocks([PointCategoryRepository])
void main() {
  late MockPointCategoryRepository repo;
  late PointCategoryService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockPointCategoryRepository();
    sut  = PointCategoryService(repo);
  });

  PointCategory _cat({int id = 1, String name = 'Кафе'}) =>
      PointCategory(id: id, name: name, createdAt: DateTime(2024));

  group('getCategory', () {
    test('возвращает категорию точки', () async {
      when(repo.findById(1)).thenAnswer((_) async => _cat());
      expect((await sut.getCategory(1))?.name, 'Кафе');
    });
    test('возвращает null если не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getCategory(99), isNull);
    });
  });

  group('getAllCategories', () {
    test('возвращает все категории', () async {
      when(repo.findAll()).thenAnswer((_) async => [_cat(), _cat(id: 2, name: 'Ресторан')]);
      expect((await sut.getAllCategories()).length, 2);
    });
  });

  group('createCategory', () {
    test('делегирует в репозиторий', () async {
      final cat = _cat();
      when(repo.create(cat)).thenAnswer((_) async => cat);
      expect((await sut.createCategory(cat)).name, 'Кафе');
    });
  });

  group('updateCategory', () {
    test('делегирует в репозиторий', () async {
      when(repo.update(1, any)).thenAnswer((_) async => _cat(name: 'Updated'));
      expect((await sut.updateCategory(1, {'name': 'Updated'})).name, 'Updated');
    });
  });

  group('deleteCategory', () {
    test('делегирует в репозиторий', () async {
      when(repo.delete(1)).thenAnswer((_) async {});
      await expectLater(sut.deleteCategory(1), completes);
      verify(repo.delete(1)).called(1);
    });
  });
}
