import '../repositories/OrderRepository.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';

class OrderService {
  final OrderRepository _orderRepository;

  OrderService(this._orderRepository);

  Future<Order> getOrderById(int id) async {
    try {
      final result = await _orderRepository.findById(id);
      if (result == null) {
        throw Exception('Заказ не найден');
      }
      return result;
    } catch (e) {
      print('Ошибка получения заказа: $e');
      rethrow;
    }
  }

  Future<List<Order>> getAllOrders({OrderStatus? status}) async {
    try {
      final query = status != null 
          ? 'SELECT * FROM orders WHERE status = @status::order_status'
          : 'SELECT * FROM orders';
      final Map<String, dynamic> params = status != null 
          ? {'status': status.name.toLowerCase()} 
          : {};
      
      final results = await _orderRepository.query(query, params: params);
      return results.map((map) => Order.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения списка заказов: $e');
      rethrow;
    }
  }

  Future<List<Order>> getUserOrders(int userId) async {
    try {
      final results = await _orderRepository.query(
        'SELECT * FROM orders WHERE user_id = @userId',
        params: {'userId': userId},
      );
      return results.map((map) => Order.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения заказов пользователя: $e');
      rethrow;
    }
  }

  Future<Order> createOrder(Map<String, dynamic> data) async {
    try {
      _validateOrderData(data);
      
      final result = await _orderRepository.createOrder(data);
      return result;
    } catch (e) {
      print('Ошибка создания заказа: $e');
      rethrow;
    }
  }

  Future<Order> updateOrderStatus(int id, OrderStatus status) async {
    try {
      final result = await _orderRepository.updateStatus(id, status);
      if (result == null) {
        throw Exception('Заказ не найден');
      }
      return result;
    } catch (e) {
      print('Ошибка обновления статуса заказа: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      final result = await _orderRepository.deleteOrder(id);
      if (result == null) {
        throw Exception('Заказ не найден');
      }
    } catch (e) {
      print('Ошибка удаления заказа: $e');
      rethrow;
    }
  }

  void _validateOrderData(Map<String, dynamic> data) {
    if (data['user_id'] == null || data['user_id'] <= 0) {
      throw Exception('Некорректный ID пользователя');
    }
    if (data['point_id'] == null || data['point_id'] <= 0) {
      throw Exception('Некорректный ID точки');
    }
    if (data['products_id'] == null || (data['products_id'] as List).isEmpty) {
      throw Exception('Список товаров не может быть пустым');
    }
    if (data['total_price'] == null || (data['total_price'] as num) <= 0) {
      throw Exception('Некорректная сумма заказа');
    }
  }
} 