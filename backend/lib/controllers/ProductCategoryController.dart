import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductCategoryService.dart';
import '../model/entities/ProductCategory.dart';

class ProductCategoryController {
  final ProductCategoryService _service;
  final Router _router = Router();

  ProductCategoryController(this._service) {
    _router.get('/', _getAll);
    _router.post('/', _create);
    _router.get('/<id>', _getById);
    _router.put('/<id>', _update);
    _router.delete('/<id>', _delete);
  }

  Router get router => _router;

  Future<Response> _getById(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      final category = await _service.getById(categoryId);
      if (category == null) {
        return Response.notFound(
          jsonEncode({'error': 'Категория не найдена'}),
          headers: _getCorsHeaders(),
        );
      }
      return Response.ok(
        jsonEncode(category.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getAll(Request request) async {
    try {
      final categories = await _service.getAll();
      return Response.ok(
        jsonEncode(categories.map((c) => c.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _create(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      
      if (data['name'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'Поле name обязательно'}),
          headers: _getCorsHeaders(),
        );
      }

      final category = ProductCategory(
        id: 0,
        name: data['name'] as String,
        description: data['description'] as String?,
        createdAt: DateTime.now(),
      );

      final createdCategory = await _service.create(category);
      return Response.ok(
        jsonEncode(createdCategory.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка создания категории: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _update(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      
      final category = ProductCategory(
        id: categoryId,
        name: data['name'] as String,
        description: data['description'] as String?,
        createdAt: DateTime.now(),
      );

      final updatedCategory = await _service.update(category);
      return Response.ok(
        jsonEncode(updatedCategory.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка обновления категории: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _delete(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      await _service.delete(categoryId);
      return Response.ok(
        jsonEncode({'message': 'Категория успешно удалена'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка удаления категории: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }
} 