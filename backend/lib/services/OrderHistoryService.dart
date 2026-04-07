import '../repositories/OrderHistoryRepository.dart';
import '../model/entities/OrderHistory.dart';
import '../model/enums/HistoryStatus.dart';

class OrderHistoryService {
  final OrderHistoryRepository _orderHistoryRepository;

  OrderHistoryService(this._orderHistoryRepository);

  Future<OrderHistory> getOrderHistoryById(int id) async {
    try {
      final orderHistory = await _orderHistoryRepository.findById(id);
      if (orderHistory == null) {
        throw Exception('История заказа не найдена');
      }
      return orderHistory;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderHistory>> getUserOrderHistory(int userId) async {
    try {
      return await _orderHistoryRepository.findByUserId(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderHistory>> getPointOrderHistory(int pointId) async {
    try {
      return await _orderHistoryRepository.findByPointId(pointId);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderHistory> createOrderHistory({
    required int orderId,
    required int pointId,
    required int userId,
    required DateTime orderDate,
    double totalSum = 0,
    HistoryStatus status = HistoryStatus.pending,
  }) async {
    try {
      final orderHistory = OrderHistory(
        id: 0, // ID будет присвоен базой данных
        orderId: orderId,
        pointId: pointId,
        userId: userId,
        orderDate: orderDate,
        totalSum: totalSum,
        status: status,
      );
      return await _orderHistoryRepository.create(orderHistory);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderHistory> completeOrder(
    int id, {
    required double totalSum,
    required int co2Saved,
    String? receiptLink,
    double? discountApplied,
    String? promoCodeUsed,
    String? notes,
  }) async {
    try {
      final orderHistory = await getOrderHistoryById(id);
      orderHistory.completeOrder(
        totalSum: totalSum,
        co2Saved: co2Saved,
        receiptLink: receiptLink,
        discountApplied: discountApplied,
        promoCodeUsed: promoCodeUsed,
        notes: notes,
      );
      return await _orderHistoryRepository.update(orderHistory);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderHistory> cancelOrder(int id, String reason) async {
    try {
      final orderHistory = await getOrderHistoryById(id);
      orderHistory.cancelOrder(reason);
      return await _orderHistoryRepository.update(orderHistory);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderHistory>> getOrdersByStatus(HistoryStatus status) async {
    try {
      return await _orderHistoryRepository.getByStatus(status);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderHistory>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _orderHistoryRepository.getByDateRange(startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }
} 