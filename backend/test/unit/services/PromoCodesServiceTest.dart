import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PromoCodesService.dart';
import 'package:backend/repositories/PromoCodesRepository.dart';
import 'package:backend/model/entities/PromoCodes.dart';
import 'package:backend/model/enums/DiscountType.dart';

import 'PromoCodesServiceTest.mocks.dart';

@GenerateMocks([PromoCodesRepository])
void main() {
  late MockPromoCodesRepository repo;
  late PromoCodesService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockPromoCodesRepository();
    sut  = PromoCodesService(repo);
  });

  // ─── fixtures ────────────────────────────────────────────────────────────
  PromoCodes _promo({
    int id = 1,
    String code = 'SAVE10',
    bool isActive = true,
    double minOrderSum = 100.0,
    double discountValue = 10.0,
    DiscountType type = DiscountType.percentage,
    List<int>? applicableProducts,
    List<int>? applicablePoints,
    int? usageLimit,
    int currentUsage = 0,
  }) =>
      PromoCodes(
        id: id,
        code: code,
        description: 'desc',
        startDate: DateTime(2020),
        endDate: DateTime(2099),
        minOrderSum: minOrderSum,
        discountType: type,
        discountValue: discountValue,
        isActive: isActive,
        applicableProducts: applicableProducts,
        applicablePoints: applicablePoints,
        usageLimit: usageLimit,
        currentUsage: currentUsage,
      );

  // ── getPromoCodeById ──────────────────────────────────────────────────────
  group('getPromoCodeById', () {
    test('возвращает промокод', () async {
      when(repo.findById(1)).thenAnswer((_) async => _promo());
      final result = await sut.getPromoCodeById(1);
      expect(result.code, 'SAVE10');
    });

    test('бросает если не найден', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getPromoCodeById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getPromoCodeByCode ────────────────────────────────────────────────────
  group('getPromoCodeByCode', () {
    test('возвращает промокод по коду', () async {
      when(repo.findByCode('SAVE10')).thenAnswer((_) async => _promo());
      final result = await sut.getPromoCodeByCode('SAVE10');
      expect(result.id, 1);
    });

    test('бросает если не найден', () async {
      when(repo.findByCode('BAD')).thenAnswer((_) async => null);
      expect(() => sut.getPromoCodeByCode('BAD'), throwsA(isA<Exception>()));
    });
  });

  // ── calculateDiscount ──────────────────────────────────────────────────────
  group('calculateDiscount', () {
    test('бросает если промокод не найден', () async {
      when(repo.findByCode(any)).thenAnswer((_) async => null);
      expect(
        () => sut.calculateDiscount('INVALID', 500, null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если промокод неактивен', () async {
      when(repo.findByCode('OFF')).thenAnswer((_) async => _promo(code: 'OFF', isActive: false));
      expect(
        () => sut.calculateDiscount('OFF', 500, null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если сумма заказа меньше минимальной', () async {
      when(repo.findByCode('SAVE10')).thenAnswer((_) async => _promo(minOrderSum: 500.0));
      expect(
        () => sut.calculateDiscount('SAVE10', 100.0, null, null),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если продукт не подходит', () async {
      when(repo.findByCode('SAVE10'))
          .thenAnswer((_) async => _promo(applicableProducts: [1, 2]));
      expect(
        () => sut.calculateDiscount('SAVE10', 500.0, 99, null),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если точка не подходит', () async {
      when(repo.findByCode('SAVE10'))
          .thenAnswer((_) async => _promo(applicablePoints: [1, 2]));
      expect(
        () => sut.calculateDiscount('SAVE10', 500.0, null, 99),
        throwsA(isA<Exception>()),
      );
    });

    test('возвращает корректный процентный дисконт', () async {
      when(repo.findByCode('SAVE10')).thenAnswer((_) async => _promo());
      when(repo.incrementUsage(any)).thenAnswer((_) async {});
      final discount = await sut.calculateDiscount('SAVE10', 200.0, null, null);
      expect(discount, closeTo(20.0, 0.001)); // 10% от 200
    });

    test('возвращает фиксированный дисконт', () async {
      when(repo.findByCode('FLAT20'))
          .thenAnswer((_) async => _promo(code: 'FLAT20', type: DiscountType.fixed, discountValue: 20.0));
      when(repo.incrementUsage(any)).thenAnswer((_) async {});
      final discount = await sut.calculateDiscount('FLAT20', 200.0, null, null);
      expect(discount, 20.0);
    });

    test('инкрементирует использование после расчёта', () async {
      when(repo.findByCode('SAVE10')).thenAnswer((_) async => _promo());
      when(repo.incrementUsage(1)).thenAnswer((_) async {});
      await sut.calculateDiscount('SAVE10', 200.0, null, null);
      verify(repo.incrementUsage(1)).called(1);
    });
  });

  // ── getActivePromoCodes ───────────────────────────────────────────────────
  group('getActivePromoCodes', () {
    test('возвращает список активных промокодов', () async {
      when(repo.getActivePromoCodes()).thenAnswer((_) async => [_promo(), _promo(id: 2, code: 'SAVE20')]);
      final result = await sut.getActivePromoCodes();
      expect(result.length, 2);
    });
  });
}
