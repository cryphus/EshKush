import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/ProductsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

class ProductsController {
  final ProductsService _productsService;

  ProductsController(this._productsService);

  Future<Response> getAllProducts(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final products = await _productsService.getAllProducts();
      
      final response = Response.ok(
        jsonEncode(products.map((p) => p.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения списка продуктов', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> getProductById(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'Некорректный ID продукта');
      }

      final product = await _productsService.getProductById(productId);
      
      final response = Response.ok(
        jsonEncode(product.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения продукта', e);
      return _createErrorResponse(404, 'Продукт не найден');
    }
  }

  Future<Response> createProduct(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeProductData(data);
        final product = await _productsService.createProduct(sanitizedData);
        
        await LoggingUtils.logInfo(
          'Создан новый продукт',
          context: {
            'productId': product.id,
            'name': product.name,
          },
        );

        final response = Response(201,
          body: jsonEncode(product.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          await response.readAsString(),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания продукта', e);
      return _createErrorResponse(400, 'Ошибка создания: $e');
    }
  }

  Future<Response> updateProduct(Request request, String id) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'Некорректный ID продукта');
      }

      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeProductData(data);
        final product = await _productsService.updateProduct(productId, sanitizedData);
        
        await LoggingUtils.logInfo(
          'Обновлен продукт',
          context: {
            'productId': product.id,
            'name': product.name,
          },
        );

        final response = Response.ok(
          jsonEncode(product.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          await response.readAsString(),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления продукта', e);
      return _createErrorResponse(400, 'Ошибка обновления: $e');
    }
  }

  Future<Response> deleteProduct(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'Некорректный ID продукта');
      }

      await _productsService.deleteProduct(productId);
      
      await LoggingUtils.logInfo(
        'Удален продукт',
        context: {'productId': productId},
      );

      final response = Response.ok(
        jsonEncode({'message': 'Продукт успешно удален'}),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления продукта', e);
      return _createErrorResponse(500, 'Ошибка удаления: $e');
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
  }

  Response _createErrorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: _getCorsHeaders(),
    );
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