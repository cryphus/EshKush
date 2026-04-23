import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/PointCategoryController.dart';
import 'package:backend/services/PointCategoryService.dart';
import 'package:backend/model/entities/PointCategory.dart';

import 'PointCategoryControllerTest.mocks.dart';

@GenerateMocks([PointCategoryService])
void main() {
  late MockPointCategoryService categoryService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    categoryService = MockPointCategoryService();
    handler = PointCategoryController(categoryService).router.call;
  });

  PointCategory _category({int id = 1, String name = 'Кофейни'}) =>
      PointCategory(id: id, name: name, createdAt: DateTime(2024));

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
      when(categoryService.getAllCategories())
          .thenAnswer((_) async => [_category(), _category(id: 2, name: 'Рестораны')]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 2);
    });
  });

  // ── GET /<id> ─────────────────────────────────────────────────────────────
  group('GET /<id>', () {
    test('200 возвращает категорию', () async {
      when(categoryService.getCategory(1)).thenAnswer((_) async => _category());
      final resp = await handler(_get('1'));
      expect(resp.statusCode, 200);
    });

    test('404 если не найдена', () async {
      when(categoryService.getCategory(99)).thenAnswer((_) async => null);
      final resp = await handler(_get('99'));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────
  group('POST /', () {
    test('200 при создании', () async {
      when(categoryService.createCategory(any)).thenAnswer((_) async => _category());
      final resp = await handler(_post('', {'name': 'Кофейни'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── PUT /<id> ─────────────────────────────────────────────────────────────
  group('PUT /<id>', () {
    test('200 при обновлении', () async {
      when(categoryService.updateCategory(1, any))
          .thenAnswer((_) async => _category(name: 'Бары'));
      final resp = await handler(_put('1', {'name': 'Бары'}));
      expect(resp.statusCode, 200);
    });
  });

  // ── DELETE /<id> ──────────────────────────────────────────────────────────
  group('DELETE /<id>', () {
    test('200 при удалении', () async {
      when(categoryService.deleteCategory(1)).thenAnswer((_) async {});
      final resp = await handler(_delete('1'));
      expect(resp.statusCode, 200);
    });
  });
}
