import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/OrderService.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/AuthUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import 'dart:convert';

class OrderController {
  final OrderService _orderService;

  OrderController(this._orderService);

  Router get router {
    final router = Router();

    router.get('/', _getAllOrders);
    router.get('/<id>', _getOrderById);
    router.get('/user/<userId>', _getUserOrders);
    router.post('/', _createOrder);
    router.put('/<id>/status', _updateOrderStatus);
    router.delete('/<id>', _deleteOrder);

    return router;
  }

  Future<Response> _getAllOrders(Request request) async {
    try {
      final status = request.url.queryParameters['status'];
      final orders = await _orderService.getAllOrders(
        status: status != null ? OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
          orElse: () => OrderStatus.pending,
        ) : null,
      );

      return Response.ok(
        orders.map((o) => o.toJson()).toList().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getOrderById(Request request) async {
    try {
      final id = int.parse(request.params['id']!);
      final order = await _orderService.getOrderById(id);

      return Response.ok(
        order.toJson().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.notFound(
        {'error': 'Заказ не найден'}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getUserOrders(Request request) async {
    try {
      final userId = int.parse(request.params['userId']!);
      final orders = await _orderService.getUserOrders(userId);

      return Response.ok(
        orders.map((o) => o.toJson()).toList().toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          jsonEncode({'error': 'Необходима авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final data = await request.readAsString();
      print('Полученные данные: ${SafeLoggingUtils.sanitizeString(data)}');
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      
      // Преобразуем все числовые значения в правильные типы
      final orderData = {
        'user_id': jsonData['user_id'],
        'point_id': jsonData['point_id'],
        'products_id': jsonData['products_id'],
        'total_price': jsonData['total_price'] is String 
            ? double.parse(jsonData['total_price']) 
            : (jsonData['total_price'] as num).toDouble(),
        'partner_id': jsonData['partner_id'],
        'date': jsonData['date'] ?? DateTime.now().toIso8601String(),
      };

      print('Данные для создания заказа: $orderData');
      
      final order = await _orderService.createOrder(orderData);

      return Response.ok(
        jsonEncode(order.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      print('Ошибка в контроллере: $e');
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _updateOrderStatus(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      final data = await request.readAsString();
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      final status = OrderStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == jsonData['status'].toString().toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
      
      final order = await _orderService.updateOrderStatus(id, status);

      return Response.ok(
        jsonEncode(order.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deleteOrder(Request request) async {
    try {
      if (!await _isAuthorized(request)) {
        return Response.unauthorized(
          {'error': 'Необходима авторизация'}.toString(),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.parse(request.params['id']!);
      await _orderService.deleteOrder(id);

      return Response.ok(
        {'message': 'Заказ успешно удален'}.toString(),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.badRequest(
        body: {'error': e.toString()}.toString(),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<bool> _isAuthorized(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null) return false;

    try {
      final token = authHeader.split(' ').last;
      final payload = await AuthUtils.verifyToken(token);
      return payload != null;
    } catch (e) {
      return false;
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
      'Content-Type': 'application/json',
    };
  }
} 