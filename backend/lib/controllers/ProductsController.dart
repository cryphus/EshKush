import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';

class ProductsController {
  final ProductsService _productsService;

  ProductsController(this._productsService);

  Router get router {
    final router = Router();

    router.get('/', getAllProducts);
    router.get('/<id>', getProductById);
    router.get('/point/<pointId>', getProductsByPointId);
    router.get('/category/<categoryId>', getProductsByCategory);
    router.get('/<id>/categories', getProductCategories);
    router.post('/', createProduct);
    router.put('/<id>', updateProduct);
    router.put('/<id>/categories', updateProductCategories);
    router.delete('/<id>', deleteProduct);

    return router;
  }

  Future<Response> getAllProducts(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final products = await _productsService.getAllProducts();
      final responseBody = jsonEncode(products.map((p) => p.toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
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
      final responseBody = jsonEncode(product.toJson());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
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
      SafeLoggingUtils.logData('Полученные данные', data);
      print('Тип price: ${data['price'].runtimeType}');
      print('Тип weight: ${data['weight'].runtimeType}');
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeProductData(data);
        SafeLoggingUtils.logData('Очищенные данные', sanitizedData);
        print('Тип price после очистки: ${sanitizedData['price'].runtimeType}');
        print('Тип weight после очистки: ${sanitizedData['weight'].runtimeType}');
        
        final product = await _productsService.createProduct(sanitizedData);
        print('Созданный продукт: ${product.toJson()}');
        
        await LoggingUtils.logInfo(
          'Создан новый продукт',
          context: {
            'productId': product.id,
            'name': product.name,
          },
        );

        final responseBody = jsonEncode(product.toJson());
        final response = Response(201,
          body: responseBody,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          responseBody,
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
        final sanitizedData = ValidationUtils.validateAndSanitizeProductDataForUpdate(data);
        final product = await _productsService.updateProduct(productId, sanitizedData);
        
        await LoggingUtils.logInfo(
          'Обновлен продукт',
          context: {
            'productId': product.id,
            'name': product.name,
          },
        );

        final responseBody = jsonEncode(product.toJson());
        final response = Response.ok(
          responseBody,
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          responseBody,
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

      final responseBody = jsonEncode({'message': 'Продукт успешно удален'});
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления продукта', e);
      return _createErrorResponse(500, 'Ошибка удаления: $e');
    }
  }

  Future<Response> getProductsByCategory(Request request, String categoryId) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final categoryIdInt = int.tryParse(categoryId);
      if (categoryIdInt == null) {
        return _createErrorResponse(400, 'Некорректный ID категории');
      }

      final products = await _productsService.getProductsByCategory(categoryIdInt);
      final responseBody = jsonEncode(products.map((p) => p.toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения продуктов по категории', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> getProductCategories(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final productId = int.parse(id);
      final categories = await _productsService.getProductCategories(productId);
      final responseBody = jsonEncode(categories.map((c) => c.toJson()).toList());
      return Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения категорий продукта', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> updateProductCategories(Request request, String id) async {
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

      final productId = int.parse(id);
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final categoryIds = (data['categoryIds'] as List).cast<int>();
      
      final categories = await _productsService.updateProductCategories(productId, categoryIds);
      final responseBody = jsonEncode(categories.map((c) => c.toJson()).toList());
      return Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления категорий продукта', e);
      return _createErrorResponse(500, 'Ошибка: $e');
    }
  }

  Future<Response> getProductsByPointId(Request request, String pointId) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final pointIdInt = int.tryParse(pointId);
      if (pointIdInt == null) {
        return _createErrorResponse(400, 'Некорректный ID точки');
      }

      final products = await _productsService.getProductsByPointId(pointIdInt);
      final responseBody = jsonEncode(products.map((p) => p.toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения продуктов по ID точки', e);
      return _createErrorResponse(500, 'Ошибка: $e');
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