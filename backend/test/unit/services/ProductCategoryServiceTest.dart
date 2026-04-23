import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ProductCategoryService.dart';
import 'package:backend/repositories/ProductCategoryRepository.dart';
import 'package:backend/model/entities/ProductCategory.dart';

import 'ProductCategoryServiceTest.mocks.dart';

@GenerateMocks([ProductCategoryRepository])
void main() {
  late MockProductCategoryRepository repo;
  late ProductCategoryService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockProductCategoryRepository();
    sut  = ProductCategoryService(repo);
  });

  ProductCategory _cat({int id = 1, String name = 'Напитки'}) =>
      ProductCategory(id: id, name: name, createdAt: DateTime(2024));

  group('getById', () {
    test('возвращает категорию', () async {
      when(repo.findById(1)).thenAnswer((_) async => _cat());
      expect((await sut.getById(1))?.name, 'Напитки');
    });
    test('возвращает null если не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getById(99), isNull);
    });
  });

  group('getAll', () {
    test('возвращает все категории', () async {
      when(repo.findAll()).thenAnswer((_) async => [_cat(id: 1), _cat(id: 2, name: 'Еда')]);
      expect((await sut.getAll()).length, 2);
    });
  });

  group('create', () {
    test('делегирует в репозиторий', () async {
      final cat = _cat();
      when(repo.create(cat)).thenAnswer((_) async => cat);
      final result = await sut.create(cat);
      expect(result.name, 'Напитки');
    });
  });

  group('update', () {
    test('делегирует в репозиторий', () async {
      final cat = _cat(name: 'Updated');
      when(repo.update(cat)).thenAnswer((_) async => cat);
      expect((await sut.update(cat)).name, 'Updated');
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
