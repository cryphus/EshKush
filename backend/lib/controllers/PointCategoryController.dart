import 'package:shelf/shelf.dart';
import '../services/PointCategoryService.dart';
import '../model/entities/PointCategory.dart';

class PointCategoryController {
  final PointCategoryService _service;

  PointCategoryController(this._service);

  Future<Response> getById(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id']!);
      final category = await _service.getById(id);
      if (category == null) {
        return Response.notFound('Категория не найдена');
      }
      return Response.ok(category.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка получения категории: $e');
    }
  }

  Future<Response> getAll(Request request) async {
    try {
      final categories = await _service.getAll();
      return Response.ok(categories.map((c) => c.toJson()).toList().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка получения категорий: $e');
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await request.readAsString();
      final json = Map<String, dynamic>.from(body as Map);
      final category = PointCategory.fromJson(json);
      final created = await _service.create(category);
      return Response.ok(created.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка создания категории: $e');
    }
  }

  Future<Response> update(Request request) async {
    try {
      final body = await request.readAsString();
      final json = Map<String, dynamic>.from(body as Map);
      final category = PointCategory.fromJson(json);
      final updated = await _service.update(category);
      return Response.ok(updated.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка обновления категории: $e');
    }
  }

  Future<Response> delete(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id']!);
      await _service.delete(id);
      return Response.ok('Категория успешно удалена');
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка удаления категории: $e');
    }
  }
} 