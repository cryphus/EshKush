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
import '../model/dto/responses/PointResponseDto.dart';
import '../model/dto/requests/CreateProductDto.dart';
import '../model/dto/requests/UpdateProductDto.dart';
import '../utils/PaginationUtils.dart';
import '../utils/RequestBodyUtils.dart';

class ProductsController {
  final ProductsService _productsService;

  ProductsController(this._productsService);

  Router get router {
    final router = Router();

    router.get('/', getAllProducts);
    router.get('/feed', getFeed);
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
      // Фильтр ?point_id=N — товары конкретной точки (используется фронтендом).
      final rawPointId = request.url.queryParameters['point_id'];
      final pointId = rawPointId != null ? int.tryParse(rawPointId) : null;
      if (rawPointId != null && pointId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный point_id',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }
      final products = pointId != null
          ? await _productsService.getProductsByPointId(pointId,
              limit: pagination.limit, offset: pagination.offset)
          : await _productsService.getAllProducts(
              limit: pagination.limit, offset: pagination.offset);
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
      await LoggingUtils.logError('Ошибка получения списка продуктов', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID продукта',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
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
      await LoggingUtils.logError('Ошибка получения продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponseWithMessage('Продукт не найден',
          code: ErrorCode.notFound, headers: _getCorsHeaders());
    }
  }

  Future<Response> createProduct(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isPartnerOrAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final data = RequestBodyUtils.decodeJsonObject(body);
      SafeLoggingUtils.logData('Полученные данные', data);

      try {
        final createDto = CreateProductDto.fromJson(data);

        final product =
            await _productsService.createProduct(createDto.toEntityData());
        await LoggingUtils.logInfo(
          'Продукт успешно создан',
          context: {
            'productId': product.id,
            'name': product.name,
          },
          requestId: RequestContextUtils.getRequestId(request),
        );

        final productDto = ProductResponseDto.fromEntity(product);
        final responseBody = jsonEncode(productDto.toJson());
        final response = Response(
          201,
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
        return ErrorResponseUtils.errorResponse(e,
            requestId: RequestContextUtils.getRequestId(request),
            headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> updateProduct(Request request, String id) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isPartnerOrAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID продукта',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }

      final data = RequestBodyUtils.decodeJsonObject(body);

      try {
        final updateDto = UpdateProductDto.fromJson(data);
        final product = await _productsService.updateProduct(
            productId, updateDto.toEntityData());

        await LoggingUtils.logInfo(
          'Продукт успешно обновлён',
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
        return ErrorResponseUtils.errorResponse(e,
            requestId: RequestContextUtils.getRequestId(request),
            headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID продукта',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }

      await _productsService.deleteProduct(productId);

      await LoggingUtils.logInfo(
        'Продукт успешно удалён',
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
      await LoggingUtils.logError('Ошибка удаления продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getProductsByCategory(
      Request request, String categoryId) async {
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
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID категории',
            headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final products = await _productsService.getProductsByCategory(
          categoryIdInt,
          limit: pagination.limit,
          offset: pagination.offset);
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
      await LoggingUtils.logError('Ошибка получения продуктов по категории', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID продукта',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }
      final categories = await _productsService.getProductCategories(productId);
      final responseBody =
          jsonEncode(categories.map((c) => c.toJson()).toList());
      return Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения категорий продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isPartnerOrAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID продукта',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }
      final body = await RequestBodyUtils.readRequiredBody(request);
      final data = RequestBodyUtils.decodeJsonObject(body);
      final categoryIds = (data['categoryIds'] as List).cast<int>();

      final categories = await _productsService.updateProductCategories(
          productId, categoryIds);
      final responseBody =
          jsonEncode(categories.map((c) => c.toJson()).toList());
      return Response.ok(
        responseBody,
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления категорий продукта', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный ID точки',
            headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final products = await _productsService.getProductsByPointId(pointIdInt,
          limit: pagination.limit, offset: pagination.offset);
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
      await LoggingUtils.logError('Ошибка получения продуктов по ID точки', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  /// Лента предложений для главного экрана: доступные сейчас товары
  /// вместе с данными их точки, одним запросом (без N+1 по каждой точке).
  Future<Response> getFeed(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final rawCityId = request.url.queryParameters['city_id'];
      final cityId = rawCityId != null ? int.tryParse(rawCityId) : null;
      if (rawCityId != null && cityId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректный city_id',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }

      final pagination = PaginationUtils.parse(request);
      final offers = await _productsService.getFeed(
          cityId: cityId, limit: pagination.limit, offset: pagination.offset);
      final responseBody = jsonEncode(PaginationUtils.wrap(
        offers
            .map((offer) => {
                  'product': ProductResponseDto.fromEntity(offer.$1).toJson(),
                  'point': PointResponseDto.fromEntity(offer.$2).toJson(),
                })
            .toList(),
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
      await LoggingUtils.logError('Ошибка получения ленты предложений', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
