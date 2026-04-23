import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ProductsController.dart';
import 'package:backend/services/ProductsService.dart';
import 'package:backend/model/entities/Product.dart';
import 'package:backend/model/entities/ProductCategory.dart';

import 'ProductsControllerTest.mocks.dart';

@GenerateMocks([ProductsService])
void main() {
  late MockProductsService productsService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    productsService = MockProductsService();
    handler = ProductsController(productsService).router.call;
  });

  Product _product({int id = 1}) => Product(
    id: id,
    name: 'Test Product',
    description: 'Description',
    price: 100.0,
    partnerId: 1,
    pointId: 1,
    weight: 0.5,
    isAvailable: true,
    isActive: true,
    createdAt: DateTime(2024),
  );

  ProductCategory _category({int id = 1}) =>
      ProductCategory(id: id, name: 'Напитки', createdAt: DateTime(2024));

  final _adminUser = <String, Object>{'id': 1, 'role': 'admin'};
  final _regularUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  Request _put(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('PUT', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  Request _delete(String path, {Map<String, Object>? user}) =>
      Request('DELETE', Uri.parse('http://localhost/$path'), context: _ctx(user));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список продуктов', () async {
      when(productsService.getAllProducts(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_product(), _product(id: 2)]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает продукт', () async {
      when(productsService.getProductById(1)).thenAnswer((_) async => _product());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('400 при нечисловом id', () async {
      final resp = await handler(_get('abc'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── GET /point/<pointId> ──────────────────────────────────────────────────
  group('GET /point/<pointId>', () {
    test('200 возвращает продукты точки', () async {
      when(productsService.getProductsByPointId(1,
              limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_product()]);
      final resp = await handler(_get('point/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /category/<categoryId> ────────────────────────────────────────────
  group('GET /category/<categoryId>', () {
    test('200 возвращает продукты категории', () async {
      when(productsService.getProductsByCategory(1,
              limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_product()]);
      final resp = await handler(_get('category/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /<id>/categories ──────────────────────────────────────────────────
  group('GET /<id>/categories', () {
    test('200 возвращает категории продукта', () async {
      when(productsService.getProductCategories(1))
          .thenAnswer((_) async => [_category()]);
      final resp = await handler(_get('1/categories'));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('', {'name': 'New'}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_post('', {'name': 'New'}, user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('201 для admin с валидными данными', () async {
      when(productsService.createProduct(any)).thenAnswer((_) async => _product());
      final resp = await handler(_post('', {
        'name': 'Test Product',
        'description': 'Description',
        'price': 100.0,
        'partner_id': 1,
        'point_id': 1,
        'weight': 0.5,
        'is_available': true,
        'is_active': true,
      }, user: _adminUser));
      expect(resp.statusCode, 201);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('1', {'name': 'Updated'}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_put('1', {'name': 'Updated'}, user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(productsService.updateProduct(1, any)).thenAnswer((_) async => _product());
      final resp = await handler(_put('1', {'name': 'Updated', 'price': 200.0}, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id>/categories ──────────────────────────────────────────────────
  group('PUT /<id>/categories', () {
    test('401 без авторизации', () async {
      final resp = await handler(_put('1/categories', {'categoryIds': [1]}));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(
          _put('1/categories', {'categoryIds': [1]}, user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(productsService.updateProductCategories(1, any))
          .thenAnswer((_) async => [_category()]);
      final resp = await handler(
          _put('1/categories', {'categoryIds': [1]}, user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('401 без авторизации', () async {
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 401);
    });

    test('403 для обычного пользователя', () async {
      final resp = await handler(_delete('1', user: _regularUser));
      expect(resp.statusCode, 403);
    });

    test('200 для admin', () async {
      when(productsService.deleteProduct(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1', user: _adminUser));
      expect(resp.statusCode, 200);
    });
  });
}
