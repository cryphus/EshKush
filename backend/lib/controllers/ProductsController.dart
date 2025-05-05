import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/ProductsService.dart';

class ProductsController {
  final ProductsService _productsService;

  ProductsController(this._productsService);

  Future<Response> getAllProducts(Request request) async {
    try {
      final products = await _productsService.getAllProducts();
      return Response.ok(
        jsonEncode(products.map((p) => p.toJson()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка: $e');
    }
  }

  Future<Response> getProductById(Request request, String id) async {
    try {
      final product = await _productsService.getProductById(int.parse(id));
      return Response.ok(jsonEncode(product.toJson()));
    } catch (e) {
      return Response.notFound('Продукт не найден');
    }
  }

  Future<Response> createProduct(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final product = await _productsService.createProduct(data);
      return Response(201, body: jsonEncode(product.toJson()));
    } catch (e) {
      return Response.badRequest(body: 'Ошибка создания: $e');
    }
  }

  Future<Response> updateProduct(Request request, String id) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final product = await _productsService.updateProduct(int.parse(id), data);
      return Response.ok(jsonEncode(product.toJson()));
    } catch (e) {
      return Response.badRequest(body: 'Ошибка обновления: $e');
    }
  }

  Future<Response> deleteProduct(Request request, String id) async {
    try {
      await _productsService.deleteProduct(int.parse(id));
      return Response.ok('Продукт удалён');
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка удаления: $e');
    }
  }
}