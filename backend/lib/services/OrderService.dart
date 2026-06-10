import '../model/entities/Order.dart';
import '../model/entities/Product.dart';
import '../model/enums/OrderStatus.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/PointRepository.dart';
import '../repositories/ProductsRepository.dart';
import '../repositories/UserRepository.dart';
import '../utils/AppException.dart';
import '../utils/MapUtils.dart';
import '../utils/SafeLoggingUtils.dart';
import 'CacheService.dart';

class OrderService {
  final OrderRepository _orderRepository;
  final UserRepository _userRepository;
  final PointRepository _pointRepository;
  final ProductsRepository _productsRepository;
  final CacheService _cacheService;

  OrderService(
    this._orderRepository,
    this._userRepository,
    this._pointRepository,
    this._productsRepository, {
    CacheService? cacheService,
  }) : _cacheService = cacheService ?? CacheService();

  Future<Order> getOrderById(int id) async {
    final cacheKey = CacheKeys.order(id);
    final cachedOrder = await _cacheService.get<Order>(cacheKey);
    if (cachedOrder != null) {
      return cachedOrder;
    }

    final result = await _orderRepository.findById(id);
    if (result == null) {
      throw const NotFoundException('Заказ не найден');
    }

    await _cacheService.set(cacheKey, result, ttl: CacheTTL.order);
    return result;
  }

  Future<List<Order>> getAllOrders({
    OrderStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    return _orderRepository.getAllOrders(
      status: status,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Order>> getUserOrders(int userId) async {
    final cacheKey = CacheKeys.userOrders(userId);
    final cachedData = await _cacheService.get<List>(cacheKey);
    if (cachedData != null) {
      return cachedData
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    final results = await _orderRepository.query(
      'SELECT * FROM orders WHERE user_id = @userId',
      params: {'userId': userId},
    );

    final orders = results.map((map) => Order.fromJson(map)).toList();
    await _cacheService.set(cacheKey, orders, ttl: CacheTTL.order);
    return orders;
  }

  Future<Order> createOrder(Map<String, dynamic> data) async {
    SafeLoggingUtils.logData('Входящие данные', data);

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

    final created = await _orderRepository.createWithPayment(orderData);
    await _invalidateOrderCache(
      userId: created.userId,
      pointId: created.pointId,
      orderId: created.id,
    );
    return created;
  }

  Future<Order> updateOrderStatus(int id, OrderStatus status) async {
    final result = await _orderRepository.updateStatus(id, status);
    if (result == null) {
      throw const NotFoundException('Заказ не найден');
    }

    await _invalidateOrderCache(
      userId: result.userId,
      pointId: result.pointId,
      orderId: result.id,
    );
    return result;
  }

  Future<void> deleteOrder(int id) async {
    final result = await _orderRepository.deleteOrder(id);
    if (result == null) {
      throw const NotFoundException('Заказ не найден');
    }

    await _invalidateOrderCache(
      userId: result.userId,
      pointId: result.pointId,
      orderId: result.id,
    );
  }

  Future<void> _validateOrderData(Map<String, dynamic> data) async {
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

    if (results[0] == null) {
      throw const NotFoundException('Пользователь не найден');
    }
    if (results[1] == null) {
      throw const NotFoundException('Точка не найдена');
    }

    final List<int> productsId = List<int>.from(data['products_id']);
    final productsData = await _productsRepository.findByIds(productsId);
    if (productsData.length != productsId.length) {
      throw const BadRequestException('Некоторые товары не найдены');
    }

    final products = productsData.map((p) => Product.fromJson(p)).toList();
    final calculatedTotal = products.fold<double>(
      0,
      (sum, product) => sum + product.price,
    );

    final totalPrice = data['total_price'] is String
        ? double.parse(data['total_price'])
        : (data['total_price'] as num).toDouble();

    if ((calculatedTotal - totalPrice).abs() > 0.01) {
      throw const BadRequestException(
        'Сумма заказа не соответствует сумме товаров',
      );
    }
  }

  Future<void> _invalidateOrderCache({
    required int userId,
    required int pointId,
    required int orderId,
  }) async {
    await _cacheService.delete(CacheKeys.order(orderId));
    await _cacheService.delete(CacheKeys.userOrders(userId));
    await _cacheService.delete(CacheKeys.pointOrders(pointId));
  }
}
