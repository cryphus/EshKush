import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ProductsService.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/repositories/ProductsRepository.dart';
import 'package:backend/model/entities/Product.dart';
import 'package:backend/model/entities/ProductCategory.dart';

import 'ProductsServiceTest.mocks.dart';

@GenerateMocks([ProductsRepository, CacheService])
void main() {
  late MockProductsRepository productsRepo;
  late MockCacheService cache;
  late ProductsService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    productsRepo = MockProductsRepository();
    cache        = MockCacheService();
    sut          = ProductsService(productsRepo, cache);

    when(cache.get(any)).thenAnswer((_) async => null);
    when(cache.set(any, any, ttl: anyNamed('ttl'))).thenAnswer((_) async => true);
    when(cache.delete(any)).thenAnswer((_) async => true);
    when(cache.deleteByPattern(any)).thenAnswer((_) async => 0);
    when(cache.isConnected).thenReturn(true);
  });

  // ─── fixtures ────────────────────────────────────────────────────────────
  Product _product({int id = 1, String name = 'Test Product'}) => Product(
    id: id, name: name, description: 'desc', price: 100.0,
    partnerId: 1, pointId: 1, weight: 0.5,
    isAvailable: true, isActive: true,
    createdAt: DateTime(2024),
  );

  ProductCategory _category({int id = 1}) => ProductCategory(
    id: id, name: 'Cat $id', createdAt: DateTime(2024),
  );

  // ── getProductById ────────────────────────────────────────────────────────
  group('getProductById', () {
    test('кеш-хит: не обращается к репозиторию', () async {
      when(cache.get(any)).thenAnswer((_) async => _product());
      final result = await sut.getProductById(1);
      expect(result.id, 1);
      verifyNever(productsRepo.findById(any));
    });

    test('кеш-промах: загружает из БД и сохраняет в кеш', () async {
      when(productsRepo.findById(1)).thenAnswer((_) async => _product());
      final result = await sut.getProductById(1);
      expect(result.id, 1);
      verify(cache.set(any, any, ttl: anyNamed('ttl'))).called(1);
    });

    test('бросает если продукт не найден', () async {
      when(productsRepo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getProductById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getAllProducts ─────────────────────────────────────────────────────────
  group('getAllProducts', () {
    test('дефолтные параметры: кешируется', () async {
      when(productsRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_product(id: 1), _product(id: 2)]);
      final result = await sut.getAllProducts();
      expect(result.length, 2);
      verify(cache.set(any, any, ttl: anyNamed('ttl'))).called(1);
    });

    test('кастомные параметры: не кешируется', () async {
      when(productsRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_product()]);
      await sut.getAllProducts(limit: 5, offset: 10);
      verifyNever(cache.set(any, any, ttl: anyNamed('ttl')));
    });

    test('кеш-хит при дефолтных: не обращается к БД', () async {
      when(cache.get(any)).thenAnswer((_) async => [_product().toJson()]);
      await sut.getAllProducts();
      verifyNever(productsRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')));
    });
  });

  // ── createProduct ──────────────────────────────────────────────────────────
  group('createProduct', () {
    test('отрицательная цена — бросает исключение', () {
      expect(
        () => sut.createProduct({'price': -10.0}),
        throwsA(isA<Exception>()),
      );
    });

    test('отрицательный вес — бросает исключение', () {
      expect(
        () => sut.createProduct({'weight': -1.0}),
        throwsA(isA<Exception>()),
      );
    });

    test('is_active не bool — бросает исключение', () {
      expect(
        () => sut.createProduct({'is_active': 'yes'}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно создаёт и инвалидирует кеш', () async {
      when(productsRepo.create(any)).thenAnswer((_) async => _product());
      final result = await sut.createProduct({'name': 'New', 'price': 50.0});
      expect(result.id, 1);
      verify(cache.delete(any)).called(greaterThan(0));
    });
  });

  // ── updateProduct ──────────────────────────────────────────────────────────
  group('updateProduct', () {
    test('бросает если продукт не найден', () async {
      when(productsRepo.findById(99)).thenAnswer((_) async => null);
      expect(
        () => sut.updateProduct(99, {'name': 'Updated'}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно обновляет', () async {
      when(productsRepo.findById(1)).thenAnswer((_) async => _product());
      when(productsRepo.update(any)).thenAnswer((_) async => _product(name: 'Updated'));
      final result = await sut.updateProduct(1, {'name': 'Updated'});
      expect(result.name, 'Updated');
    });
  });

  // ── updateProductCategories ────────────────────────────────────────────────
  group('updateProductCategories', () {
    test('бросает если продукт не найден', () async {
      when(productsRepo.findById(99)).thenAnswer((_) async => null);
      expect(
        () => sut.updateProductCategories(99, [1]),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если категория не найдена', () async {
      when(productsRepo.findById(1)).thenAnswer((_) async => _product());
      when(productsRepo.findCategoryById(99)).thenAnswer((_) async => null);
      expect(
        () => sut.updateProductCategories(1, [99]),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно обновляет категории', () async {
      when(productsRepo.findById(1)).thenAnswer((_) async => _product());
      when(productsRepo.findCategoryById(1)).thenAnswer((_) async => _category());
      when(productsRepo.updateProductCategories(any, any)).thenAnswer((_) async {});
      when(productsRepo.getCategoriesForProduct(any)).thenAnswer((_) async => [_category()]);
      final result = await sut.updateProductCategories(1, [1]);
      expect(result.length, 1);
    });
  });
}
