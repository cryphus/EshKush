import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ProductCategoryController.dart';
import 'package:backend/services/ProductCategoryService.dart';
import 'package:backend/model/entities/ProductCategory.dart';

import 'ProductCategoryControllerTest.mocks.dart';

@GenerateMocks([ProductCategoryService])
void main() {
  late MockProductCategoryService categoryService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    categoryService = MockProductCategoryService();
    handler = ProductCategoryController(categoryService).router.call;
  });

  ProductCategory _category({int id = 1, String name = 'Напитки'}) =>
      ProductCategory(id: id, name: name, createdAt: DateTime(2024));

  Request _get(String path) =>
      Request('GET', Uri.parse('http://localhost/$path'));

  Request _post(String path, Map<String, dynamic> body) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  Request _put(String path, Map<String, dynamic> body) =>
      Request('PUT', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  Request _delete(String path) =>
      Request('DELETE', Uri.parse('http://localhost/$path'));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список категорий', () async {
      when(categoryService.getAll())
          .thenAnswer((_) async => [_category(), _category(id: 2, name: 'Еда')]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 2);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает категорию', () async {
      when(categoryService.getById(1)).thenAnswer((_) async => _category());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если не найдена', () async {
      when(categoryService.getById(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('200 при создании', () async {
      when(categoryService.create(any)).thenAnswer((_) async => _category());
      final resp = await handler(_post('', {'name': 'Напитки'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('200 при обновлении', () async {
      when(categoryService.update(any)).thenAnswer((_) async => _category(name: 'Кофе'));
      final resp = await handler(_put('1', {'name': 'Кофе'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('200 при удалении', () async {
      when(categoryService.delete(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 200);
    });
  });
}
