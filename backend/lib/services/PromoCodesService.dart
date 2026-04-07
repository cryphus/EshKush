import '../repositories/PromoCodesRepository.dart';
import '../model/entities/PromoCodes.dart';
import '../model/enums/DiscountType.dart';

class PromoCodesService {
  final PromoCodesRepository _promoCodesRepository;

  PromoCodesService(this._promoCodesRepository);

  Future<PromoCodes> getPromoCodeById(int id) async {
    try {
      final promoCode = await _promoCodesRepository.findById(id);
      if (promoCode == null) {
        throw Exception('Промокод не найден');
      }
      return promoCode;
    } catch (e) {
      rethrow;
    }
  }

  Future<PromoCodes> getPromoCodeByCode(String code) async {
    try {
      final promoCode = await _promoCodesRepository.findByCode(code);
      if (promoCode == null) {
        throw Exception('Промокод не найден');
      }
      return promoCode;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PromoCodes>> getActivePromoCodes() async {
    try {
      return await _promoCodesRepository.getActivePromoCodes();
    } catch (e) {
      rethrow;
    }
  }

  Future<PromoCodes> createPromoCode({
    required String code,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required double minOrderSum,
    required DiscountType discountType,
    required double discountValue,
    bool isActive = true,
    int? usageLimit,
    List<int>? applicableProducts,
    List<int>? applicablePoints,
  }) async {
    try {
      final promoCode = PromoCodes(
        id: 0, // ID будет присвоен базой данных
        code: code,
        description: description,
        startDate: startDate,
        endDate: endDate,
        minOrderSum: minOrderSum,
        discountType: discountType,
        discountValue: discountValue,
        isActive: isActive,
        usageLimit: usageLimit,
        currentUsage: 0,
        applicableProducts: applicableProducts,
        applicablePoints: applicablePoints,
      );
      return await _promoCodesRepository.create(promoCode);
    } catch (e) {
      rethrow;
    }
  }

  Future<PromoCodes> updatePromoCode(PromoCodes promoCode) async {
    try {
      return await _promoCodesRepository.update(promoCode);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePromoCode(int id) async {
    try {
      await _promoCodesRepository.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<double> calculateDiscount(String code, double orderSum, int? productId, int? pointId) async {
    try {
      final promoCode = await getPromoCodeByCode(code);
      
      if (!promoCode.isValid) {
        throw Exception('Промокод недействителен');
      }

      if (orderSum < promoCode.minOrderSum) {
        throw Exception('Сумма заказа меньше минимальной');
      }

      if (productId != null && !promoCode.isApplicableToProduct(productId)) {
        throw Exception('Промокод не применим к данному товару');
      }

      if (pointId != null && !promoCode.isApplicableToPoint(pointId)) {
        throw Exception('Промокод не применим к данной точке');
      }

      final discount = promoCode.calculateDiscount(orderSum);
      await _promoCodesRepository.incrementUsage(promoCode.id);
      
      return discount;
    } catch (e) {
      rethrow;
    }
  }
} 