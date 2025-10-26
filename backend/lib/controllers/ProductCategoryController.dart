import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductCategoryService.dart';
import '../model/entities/ProductCategory.dart';
import '../utils/ValidationUtils.dart';

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
          jsonEncode({'error': 'РљР°С‚РµРіРѕСЂРёСЏ РЅРµ РЅР°Р№РґРµРЅР°'}),
          headers: _getCorsHeaders(),
        );
      }
      return Response.ok(
        jsonEncode(category.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}),
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
        body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _create(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final sanitized = ValidationUtils.validateAndSanitizeCategoryData(data);

      final category = ProductCategory(
        id: 0,
        name: sanitized['name'] as String,
        description: sanitized['description'] as String?,
        createdAt: DateTime.now(),
      );

      final createdCategory = await _service.create(category);
      return Response.ok(
        jsonEncode(createdCategory.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РєР°С‚РµРіРѕСЂРёРё: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _update(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      final sanitized = ValidationUtils.validateAndSanitizeCategoryData(data);
      
      final category = ProductCategory(
        id: categoryId,
        name: sanitized['name'] as String,
        description: sanitized['description'] as String?,
        createdAt: DateTime.now(),
      );

      final updatedCategory = await _service.update(category);
      return Response.ok(
        jsonEncode(updatedCategory.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёРё: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _delete(Request request, String id) async {
    try {
      final categoryId = int.parse(id);
      await _service.delete(categoryId);
      return Response.ok(
        jsonEncode({'message': 'РљР°С‚РµРіРѕСЂРёСЏ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅР°'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёРё: $e'}),
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
