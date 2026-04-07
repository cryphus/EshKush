import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductCategoryService.dart';
import '../model/entities/ProductCategory.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';

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
        return ErrorResponseUtils.errorResponseWithMessage('Категория не найдена', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }
      return Response.ok(
        jsonEncode(category.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
