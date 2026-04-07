import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/ProductsService.dart';
import '../utils/ValidationUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../model/dto/responses/ProductResponseDto.dart';
import '../model/dto/requests/CreateProductDto.dart';
import '../model/dto/requests/UpdateProductDto.dart';
import '../utils/PaginationUtils.dart';

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

      final pagination = PaginationUtils.parse(request);
      final products = await _productsService.getAllProducts(limit: pagination.limit, offset: pagination.offset);
      final responseBody = jsonEncode(PaginationUtils.wrap(
        products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList(),
        pagination,
      ));
      
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка получения транзакций по методу оплаты', headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponseWithMessage('Продукт не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

             final data = jsonDecode(body);
       SafeLoggingUtils.logData('РџРѕР»СѓС‡РµРЅРЅС‹Рµ РґР°РЅРЅС‹Рµ', data);
       
       try {
         final createDto = CreateProductDto.fromJson(data);
         
         final product = await _productsService.createProduct(createDto.toEntityData());
        await LoggingUtils.logInfo(
          'Некорректная сумма',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка получения транзакций по методу оплаты', headers: _getCorsHeaders());
      }

             final data = jsonDecode(body);
       
       try {
         final updateDto = UpdateProductDto.fromJson(data);
         final product = await _productsService.updateProduct(productId, updateDto.toEntityData());
        
        await LoggingUtils.logInfo(
          'Некорректный ID',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕРґСѓРєС‚Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Ошибка получения транзакций по методу оплаты', headers: _getCorsHeaders());
      }

      await _productsService.deleteProduct(productId);
      
      await LoggingUtils.logInfo(
        'TTL в секундах',
        context: {'productId': productId},
        requestId: RequestContextUtils.getRequestId(request),
      );

      final responseBody = jsonEncode({'message': 'Продукт успешно удалён'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID категории', headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final products = await _productsService.getProductsByCategory(categoryIdInt, limit: pagination.limit, offset: pagination.offset);
      final responseBody = jsonEncode(PaginationUtils.wrap(
        products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList(),
        pagination,
      ));
      
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request, headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа', code: ErrorCode.forbidden, headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID точки', headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final products = await _productsService.getProductsByPointId(pointIdInt, limit: pagination.limit, offset: pagination.offset);
      final responseBody = jsonEncode(PaginationUtils.wrap(
        products.map((p) => ProductResponseDto.fromEntity(p).toJson()).toList(),
        pagination,
      ));
      
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }


  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
