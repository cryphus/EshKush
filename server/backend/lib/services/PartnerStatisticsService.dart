import '../repositories/PartnerStatisticsRepository.dart';
import '../model/entities/PartnerStatistics.dart';

class PartnerStatisticsService {
  final PartnerStatisticsRepository _repository;

  PartnerStatisticsService(this._repository);

  Future<PartnerStatistics> getStatisticsById(int id) async {
    try {
      final statistics = await _repository.findById(id);
      if (statistics == null) {
        throw Exception('Статистика не найдена');
      }
      return statistics;
    } catch (e) {
      print('Ошибка получения статистики: $e');
      rethrow;
    }
  }

  Future<PartnerStatistics> getStatisticsByPartnerId(int partnerId) async {
    try {
      final statistics = await _repository.findByPartnerId(partnerId);
      if (statistics == null) {
        throw Exception('Статистика партнера не найдена');
      }
      return statistics;
    } catch (e) {
      print('Ошибка получения статистики партнера: $e');
      rethrow;
    }
  }

  Future<PartnerStatistics> getStatisticsByPointId(int pointId) async {
    try {
      final statistics = await _repository.findByPointId(pointId);
      if (statistics == null) {
        throw Exception('Статистика точки не найдена');
      }
      return statistics;
    } catch (e) {
      print('Ошибка получения статистики точки: $e');
      rethrow;
    }
  }

  Future<PartnerStatistics> createStatistics(Map<String, dynamic> data) async {
    try {
      _validateStatisticsData(data);
      
      final statistics = PartnerStatistics(
        id: 0, // ID будет присвоен базой данных
        partnerId: data['partner_id'],
        pointId: data['point_id'],
        totalOrders: (data['total_orders'] as num?)?.toInt() ?? 0,
        totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
        totalCancel: (data['total_cancel'] as num?)?.toInt() ?? 0,
        averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: data['total_reviews'] ?? 0,
        createdAt: DateTime.now(),
      );

      return await _repository.create(statistics);
    } catch (e) {
      print('Ошибка создания статистики: $e');
      rethrow;
    }
  }

  Future<PartnerStatistics> updateStatistics(int id, Map<String, dynamic> data) async {
    try {
      final currentStatistics = await _repository.findById(id);
      if (currentStatistics == null) {
        throw Exception('Статистика не найдена');
      }

      _validateUpdateData(data);

      final updatedStatistics = currentStatistics.copyWith(
        totalOrders: (data['total_orders'] as num?)?.toInt(),
        totalRevenue: (data['total_revenue'] as num?)?.toDouble(),
        totalCancel: (data['total_cancel'] as num?)?.toInt(),
        averageRating: (data['average_rating'] as num?)?.toDouble(),
        totalReviews: (data['total_reviews'] as num?)?.toInt(),
      );

      return await _repository.update(updatedStatistics);
    } catch (e) {
      print('Ошибка обновления статистики: $e');
      rethrow;
    }
  }

  Future<void> addOrder(int id, double revenue) async {
    try {
      final statistics = await _repository.findById(id);
      if (statistics == null) {
        throw Exception('Статистика не найдена');
      }

      statistics.addOrder(revenue);
      await _repository.update(statistics);
    } catch (e) {
      print('Ошибка добавления заказа в статистику: $e');
      rethrow;
    }
  }

  Future<void> addCancel(int id) async {
    try {
      final statistics = await _repository.findById(id);
      if (statistics == null) {
        throw Exception('Статистика не найдена');
      }

      statistics.addCancel();
      await _repository.update(statistics);
    } catch (e) {
      print('Ошибка добавления отмены в статистику: $e');
      rethrow;
    }
  }

  Future<void> updateRating(int id, double rating) async {
    try {
      final statistics = await _repository.findById(id);
      if (statistics == null) {
        throw Exception('Статистика не найдена');
      }

      statistics.updateRating(rating);
      await _repository.update(statistics);
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
      rethrow;
    }
  }

  Future<void> deactivateStatistics(int id) async {
    try {
      await _repository.deactivate(id);
    } catch (e) {
      print('Ошибка деактивации статистики: $e');
      rethrow;
    }
  }

  Future<void> activateStatistics(int id) async {
    try {
      await _repository.activate(id);
    } catch (e) {
      print('Ошибка активации статистики: $e');
      rethrow;
    }
  }

  void _validateStatisticsData(Map<String, dynamic> data) {
    if (data['partner_id'] == null || data['partner_id'] <= 0) {
      throw Exception('Некорректный ID партнера');
    }
    if (data['point_id'] == null || data['point_id'] <= 0) {
      throw Exception('Некорректный ID точки');
    }
    if (data['total_orders'] != null && data['total_orders'] < 0) {
      throw Exception('Количество заказов не может быть отрицательным');
    }
    if (data['total_revenue'] != null && data['total_revenue'] < 0) {
      throw Exception('Выручка не может быть отрицательной');
    }
    if (data['total_cancel'] != null && data['total_cancel'] < 0) {
      throw Exception('Количество отмен не может быть отрицательным');
    }
    if (data['average_rating'] != null && (data['average_rating'] < 0 || data['average_rating'] > 5)) {
      throw Exception('Рейтинг должен быть от 0 до 5');
    }
    if (data['total_reviews'] != null && data['total_reviews'] < 0) {
      throw Exception('Количество отзывов не может быть отрицательным');
    }
  }

  void _validateUpdateData(Map<String, dynamic> data) {
    if (data['total_orders'] != null && data['total_orders'] < 0) {
      throw Exception('Количество заказов не может быть отрицательным');
    }
    if (data['total_revenue'] != null && data['total_revenue'] < 0) {
      throw Exception('Выручка не может быть отрицательной');
    }
    if (data['total_cancel'] != null && data['total_cancel'] < 0) {
      throw Exception('Количество отмен не может быть отрицательным');
    }
    if (data['average_rating'] != null && (data['average_rating'] < 0 || data['average_rating'] > 5)) {
      throw Exception('Рейтинг должен быть от 0 до 5');
    }
    if (data['total_reviews'] != null && data['total_reviews'] < 0) {
      throw Exception('Количество отзывов не может быть отрицательным');
    }
  }
} 