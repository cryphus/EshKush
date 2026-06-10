import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PromoCodesRepository.dart';
import 'package:backend/model/entities/PromoCodes.dart';
import 'package:backend/model/enums/DiscountType.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late PromoCodesRepository repo;

  int _counter = 0;

  PromoCodes _promo({
    String? code,
    DiscountType discountType = DiscountType.percentage,
    double discountValue = 10.0,
    bool isActive = true,
  }) {
    _counter++;
    return PromoCodes(
      id: 0,
      code: code ?? 'CODE$_counter',
      description: 'Test promo $_counter',
      discountType: discountType,
      discountValue: discountValue,
      minOrderSum: 100.0,
      startDate: DateTime(2020),
      endDate: DateTime(2099),
      isActive: isActive,
      currentUsage: 0,
      applicableProducts: [],
      applicablePoints: [],
    );
  }

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PromoCodesRepository(conn);
  });

  setUp(() async {
    _counter = 0;
    await TestDb.truncate(conn, ['promo_codes']);
  });

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт промокод с id > 0', () async {
      final result = await repo.create(_promo(code: 'SAVE10'));
      expect(result.id, greaterThan(0));
      expect(result.code, 'SAVE10');
      expect(result.discountValue, 10.0);
    });

    test('сохраняет тип скидки', () async {
      final r = await repo.create(_promo(discountType: DiscountType.fixed, discountValue: 50.0));
      expect(r.discountType, DiscountType.fixed);
      expect(r.discountValue, 50.0);
    });

    test('бросает при дублирующемся code', () async {
      await repo.create(_promo(code: 'DUP'));
      expect(() => repo.create(_promo(code: 'DUP')), throwsA(anything));
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает промокод по id', () async {
      final created = await repo.create(_promo(code: 'FIND'));
      final found = await repo.findById(created.id);
      expect(found?.code, 'FIND');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByCode ────────────────────────────────────────────────────────────
  group('findByCode', () {
    test('возвращает промокод по коду', () async {
      await repo.create(_promo(code: 'BYCODE'));
      final found = await repo.findByCode('BYCODE');
      expect(found?.code, 'BYCODE');
    });

    test('возвращает null для несуществующего кода', () async {
      expect(await repo.findByCode('NOCODE'), isNull);
    });
  });

  // ── getActivePromoCodes ───────────────────────────────────────────────────
  group('getActivePromoCodes', () {
    test('возвращает только активные промокоды', () async {
      await repo.create(_promo(isActive: true));
      await repo.create(_promo(isActive: false));
      final active = await repo.getActivePromoCodes();
      expect(active.every((p) => p.isActive), isTrue);
    });

    test('возвращает пустой список если нет активных', () async {
      await repo.create(_promo(isActive: false));
      expect(await repo.getActivePromoCodes(), isEmpty);
    });
  });

  // ── incrementUsage ────────────────────────────────────────────────────────
  group('incrementUsage', () {
    test('увеличивает currentUsage на 1', () async {
      final created = await repo.create(_promo());
      expect(created.currentUsage, 0);
      await repo.incrementUsage(created.id);
      final found = await repo.findById(created.id);
      expect(found?.currentUsage, 1);
    });

    test('повторный вызов увеличивает до 2', () async {
      final created = await repo.create(_promo());
      await repo.incrementUsage(created.id);
      await repo.incrementUsage(created.id);
      final found = await repo.findById(created.id);
      expect(found?.currentUsage, 2);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет промокод', () async {
      final created = await repo.create(_promo(code: 'DEL'));
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если промокод не найден', () async {
      expect(() => repo.delete(999999), throwsA(isA<Exception>()));
    });
  });
}
