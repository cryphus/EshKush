import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PointCategoryService.dart';
import '../model/entities/PointCategory.dart';

class PointCategoryController {
  final PointCategoryService _categoryService;
  final Router _router = Router();

  PointCategoryController(this._categoryService) {
    _router.get('/', _getAllCategories);
    _router.post('/', _createCategory);
    _router.get('/<id>', _getCategory);
    _router.put('/<id>', _updateCategory);
    _router.delete('/<id>', _deleteCategory);
  }

  Router get router => _router;

  Future<Response> _getCategory(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      final category = await _categoryService.getCategory(categoryId);
      
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

  Future<Response> _getAllCategories(Request request) async {
    try {
      final categories = await _categoryService.getAllCategories();
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

  Future<Response> _createCategory(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      
      if (data['name'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'Поле name обязательно'}),
          headers: _getCorsHeaders(),
        );
      }

      final category = PointCategory(
        id: 0,
        name: data['name'] as String,
        description: data['description'] as String?,
        createdAt: DateTime.now(),
      );

      final createdCategory = await _categoryService.createCategory(category);
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

  Future<Response> _updateCategory(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      
      final updatedCategory = await _categoryService.updateCategory(categoryId, data);
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

  Future<Response> _deleteCategory(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      await _categoryService.deleteCategory(categoryId);
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