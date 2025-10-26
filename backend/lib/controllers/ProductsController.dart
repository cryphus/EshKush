import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductsService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/ProductResponseDto.dart';
import '../model/dto/requests/CreateProductDto.dart';
import '../model/dto/requests/UpdateProductDto.dart';

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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final products = await _productsService.getAllProducts();
      final responseBody = jsonEncode(products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРёСЃРєР° РїСЂРѕРґСѓРєС‚РѕРІ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getProductById(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїСЂРѕРґСѓРєС‚Р°');
      }

      final product = await _productsService.getProductById(productId);
      final productDto = ProductResponseDto.fromEntity(product);
      final responseBody = jsonEncode(productDto.toJson());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(404, 'РџСЂРѕРґСѓРєС‚ РЅРµ РЅР°Р№РґРµРЅ');
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

             final data = jsonDecode(body);
       SafeLoggingUtils.logData('РџРѕР»СѓС‡РµРЅРЅС‹Рµ РґР°РЅРЅС‹Рµ', data);
       
       try {
         final createDto = CreateProductDto.fromJson(data);
         
         final product = await _productsService.createProduct(createDto.toEntityData());
        await LoggingUtils.logInfo(
          'РЎРѕР·РґР°РЅ РЅРѕРІС‹Р№ РїСЂРѕРґСѓРєС‚',
          context: {
            'productId': product.id,
            'name': product.name,
          },
                     requestId: RequestContextUtils.getRequestId(request),
         );

         final productDto = ProductResponseDto.fromEntity(product);
         final responseBody = jsonEncode(productDto.toJson());
         final response = Response(201,
           body: responseBody,
           headers: _getCorsHeaders(),
         );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          responseBody,
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ: $e');
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
        requestId: RequestContextUtils.getRequestId(request),
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїСЂРѕРґСѓРєС‚Р°');
      }

             final data = jsonDecode(body);
       
       try {
         final updateDto = UpdateProductDto.fromJson(data);
         final product = await _productsService.updateProduct(productId, updateDto.toEntityData());
        
        await LoggingUtils.logInfo(
          'РћР±РЅРѕРІР»РµРЅ РїСЂРѕРґСѓРєС‚',
          context: {
            'productId': product.id,
            'name': product.name,
          },
                     requestId: RequestContextUtils.getRequestId(request),
         );

         final productDto = ProductResponseDto.fromEntity(product);
         final responseBody = jsonEncode(productDto.toJson());
         final response = Response.ok(
           responseBody,
           headers: _getCorsHeaders(),
         );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          responseBody,
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ: $e');
    }
  }

  Future<Response> deleteProduct(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РїСЂРѕРґСѓРєС‚Р°');
      }

      await _productsService.deleteProduct(productId);
      
      await LoggingUtils.logInfo(
        'РЈРґР°Р»РµРЅ РїСЂРѕРґСѓРєС‚',
        context: {'productId': productId},
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseBody = jsonEncode({'message': 'РџСЂРѕРґСѓРєС‚ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'});
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ: $e');
    }
  }

  Future<Response> getProductsByCategory(Request request, String categoryId) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final categoryIdInt = int.tryParse(categoryId);
      if (categoryIdInt == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID РєР°С‚РµРіРѕСЂРёРё');
      }

      final products = await _productsService.getProductsByCategory(categoryIdInt);
      final responseBody = jsonEncode(products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕРґСѓРєС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getProductCategories(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final productId = int.parse(id);
      final categories = await _productsService.getProductCategories(productId);
      final responseBody = jsonEncode(categories.map((c) => c.toJson()).toList());
      return Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёР№ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> updateProductCategories(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёР№ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getProductsByPointId(Request request, String pointId) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final pointIdInt = int.tryParse(pointId);
      if (pointIdInt == null) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ ID С‚РѕС‡РєРё');
      }

      final products = await _productsService.getProductsByPointId(pointIdInt);
      final responseBody = jsonEncode(products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList());
      
      final response = Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        responseBody,
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕРґСѓРєС‚РѕРІ РїРѕ ID С‚РѕС‡РєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(500, 'РћС€РёР±РєР°: $e');
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
