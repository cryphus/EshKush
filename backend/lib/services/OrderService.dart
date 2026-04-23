import '../repositories/OrderRepository.dart';
import '../model/entities/Order.dart';
import '../model/enums/OrderStatus.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/MapUtils.dart';
import '../repositories/UserRepository.dart';
import '../repositories/PointRepository.dart';
import '../repositories/ProductsRepository.dart';
import '../model/entities/Product.dart';

class OrderService {
  final OrderRepository _orderRepository;
  final UserRepository _userRepository;
  final PointRepository _pointRepository;
  final ProductsRepository _productsRepository;

  OrderService(
    this._orderRepository,
    this._userRepository,
    this._pointRepository,
    this._productsRepository,
  );

  Future<Order> getOrderById(int id) async {
    try {
      final result = await _orderRepository.findById(id);
      if (result == null) {
        throw Exception('Заказ не найден');
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getAllOrders({
    OrderStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _orderRepository.getAllOrders(
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
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
      rethrow;
    }
  }

  Future<Order> createOrder(Map<String, dynamic> data) async {
    try {
      SafeLoggingUtils.logData('Входящие данные', data);
      
      // Преобразуем данные в правильные типы
      final orderData = {
        'user_id': data['user_id'],
        'point_id': data['point_id'],
        'products_id': data['products_id'],
        'total_price': data['total_price'] is String 
            ? double.parse(data['total_price']) 
            : (data['total_price'] as num).toDouble(),
        'partner_id': data['partner_id'],
        'date': data['date'] ?? DateTime.now().toIso8601String(),
      };


      await _validateOrderData(orderData);
      return await _orderRepository.createWithPayment(orderData);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<void> _validateOrderData(Map<String, dynamic> data) async {
    // Проверка обязательных полей с явными сообщениями через MapUtils
    final userId = MapUtils.require<int>(data, 'user_id');
    final pointId = MapUtils.require<int>(data, 'point_id');
    final productsList = data['products_id'];
    if (productsList == null || (productsList as List).isEmpty) {
      throw ArgumentError('Список товаров не может быть пустым');
    }
    MapUtils.require<double>(data, 'total_price');

    final results = await Future.wait([
      _userRepository.findById(userId),
      _pointRepository.findById(pointId),
    ]);
    if (results[0] == null) throw Exception('Пользователь не найден');
    if (results[1] == null) throw Exception('Точка не найдена');

    // Преобразуем список в List<int>
    final List<int> productsId = List<int>.from(data['products_id']);

    // Проверка существования продуктов и подсчет общей суммы
    final productsData = await _productsRepository.findByIds(productsId);
    if (productsData.length != productsId.length) {
      throw Exception('Некоторые товары не найдены');
    }

    final products = productsData.map((p) => Product.fromJson(p)).toList();

    // Проверка соответствия суммы заказа
    final calculatedTotal = products.fold<double>(
      0,
      (sum, product) => sum + product.price,
    );
    
    // Преобразуем total_price в double
    final totalPrice = data['total_price'] is String 
        ? double.parse(data['total_price']) 
        : (data['total_price'] as num).toDouble();
    
    if ((calculatedTotal - totalPrice).abs() > 0.01) {
      throw Exception('Сумма заказа не соответствует сумме товаров');
    }
  }
} 