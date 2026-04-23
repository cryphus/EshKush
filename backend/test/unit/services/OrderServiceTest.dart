import 'dart:async';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/PointRepository.dart';
import 'package:backend/repositories/ProductsRepository.dart';
import 'package:backend/model/entities/Order.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/entities/Point.dart';
import 'package:backend/model/enums/OrderStatus.dart';
import 'package:backend/model/enums/UserRole.dart';

import 'OrderServiceTest.mocks.dart';

@GenerateMocks([OrderRepository, UserRepository, PointRepository, ProductsRepository])
void main() {
  late MockOrderRepository orderRepo;
  late MockUserRepository userRepo;
  late MockPointRepository pointRepo;
  late MockProductsRepository productsRepo;
  late OrderService sut;

  setUpAll(() {
    AppConfig.initForTesting();
  });

  setUp(() {
    orderRepo    = MockOrderRepository();
    userRepo     = MockUserRepository();
    pointRepo    = MockPointRepository();
    productsRepo = MockProductsRepository();
    sut = OrderService(orderRepo, userRepo, pointRepo, productsRepo);
  });

  // ── Фикстуры ─────────────────────────────────────────────────────────────────
  Order _order({int id = 1, double price = 100.0}) => Order(
    id: id, productsId: [1], userId: 1, pointId: 1,
    date: DateTime(2024), totalPrice: price, createdAt: DateTime(2024),
  );

  User _user() => User(
    id: 1, username: 'testuser', password: 'hash',
    number: '+79001234567', email: 'test@example.com',
    createdAt: DateTime(2024), role: UserRole.user,
  );

  Point _point() => Point(
    id: 1, name: 'Test', address: 'Addr', cityId: 1,
    products: {}, openingHours: '09:00', closingHours: '21:00',
    partnerId: 1, longitude: 37.6, latitude: 55.7,
    tags: {}, createdAt: DateTime(2024),
  );

  Map<String, dynamic> _productJson({double price = 100.0}) => {
    'id': 1, 'name': 'Product', 'description': '', 'price': price,
    'partner_id': 1, 'point_id': 1, 'weight': 0.5,
    'is_available': true, 'is_active': true,
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _orderData({double price = 100.0}) => {
    'user_id': 1, 'point_id': 1,
    'products_id': [1], 'total_price': price,
    'date': '2024-01-01T00:00:00.000Z',
  };

  // ── getOrderById ──────────────────────────────────────────────────────────────
  group('getOrderById', () {
    test('возвращает заказ если найден', () async {
      when(orderRepo.findById(1)).thenAnswer((_) async => _order());
      final result = await sut.getOrderById(1);
      expect(result.id, 1);
    });

    test('бросает исключение если не найден', () async {
      when(orderRepo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getOrderById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getAllOrders ──────────────────────────────────────────────────────────────
  group('getAllOrders', () {
    test('возвращает список заказов', () async {
      when(orderRepo.getAllOrders(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_order(id: 1), _order(id: 2)]);
      final list = await sut.getAllOrders();
      expect(list.length, 2);
    });

    test('пустой список если заказов нет', () async {
      when(orderRepo.getAllOrders(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => []);
      expect(await sut.getAllOrders(), isEmpty);
    });
  });

  // ── createOrder ───────────────────────────────────────────────────────────────
  group('createOrder — валидация', () {
    test('бросает ArgumentError при отсутствии user_id', () async {
      final data = _orderData()..remove('user_id');
      expect(() => sut.createOrder(data), throwsA(isA<ArgumentError>()));
    });

    test('бросает ArgumentError при отсутствии point_id', () async {
      final data = _orderData()..remove('point_id');
      expect(() => sut.createOrder(data), throwsA(isA<ArgumentError>()));
    });

    test('бросает если products_id пустой', () async {
      final data = {..._orderData(), 'products_id': <int>[]};
      expect(() => sut.createOrder(data), throwsA(isA<ArgumentError>()));
    });

    test('бросает если пользователь не найден', () async {
      when(userRepo.findById(1)).thenAnswer((_) async => null);
      when(pointRepo.findById(any)).thenAnswer((_) async => _point());
      when(productsRepo.findByIds(any)).thenAnswer((_) async => [_productJson()]);
      expect(() => sut.createOrder(_orderData()), throwsA(isA<Exception>()));
    });

    test('бросает если точка не найдена', () async {
      when(userRepo.findById(1)).thenAnswer((_) async => _user());
      when(pointRepo.findById(1)).thenAnswer((_) async => null);
      expect(() => sut.createOrder(_orderData()), throwsA(isA<Exception>()));
    });

    test('бросает если сумма не совпадает с ценой продуктов', () async {
      when(userRepo.findById(1)).thenAnswer((_) async => _user());
      when(pointRepo.findById(1)).thenAnswer((_) async => _point());
      when(productsRepo.findByIds([1])).thenAnswer((_) async => [_productJson(price: 200.0)]);
      // total_price = 100, но продукт стоит 200
      expect(() => sut.createOrder(_orderData(price: 100.0)), throwsA(isA<Exception>()));
    });
  });

  group('createOrder — успех и rollback', () {
    setUp(() {
      when(userRepo.findById(1)).thenAnswer((_) async => _user());
      when(pointRepo.findById(1)).thenAnswer((_) async => _point());
      when(productsRepo.findByIds([1])).thenAnswer((_) async => [_productJson(price: 100.0)]);
    });

    test('успешно создаёт заказ', () async {
      when(orderRepo.createWithPayment(any)).thenAnswer((_) async => _order());
      final result = await sut.createOrder(_orderData(price: 100.0));
      expect(result.id, 1);
      verify(orderRepo.createWithPayment(any)).called(1);
    });

    test('rollback: исключение из репозитория пробрасывается наверх', () async {
      when(orderRepo.createWithPayment(any)).thenThrow(Exception('DB rollback'));
      expect(
        () => sut.createOrder(_orderData(price: 100.0)),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('DB rollback'))),
      );
    });
  });

  // ── updateOrderStatus ─────────────────────────────────────────────────────────
  group('updateOrderStatus', () {
    test('возвращает обновлённый заказ', () async {
      when(orderRepo.updateStatus(1, OrderStatus.completed))
          .thenAnswer((_) async => _order());
      final result = await sut.updateOrderStatus(1, OrderStatus.completed);
      expect(result.id, 1);
    });

    test('бросает если заказ не найден', () async {
      when(orderRepo.updateStatus(99, any)).thenAnswer((_) async => null);
      expect(() => sut.updateOrderStatus(99, OrderStatus.completed), throwsA(isA<Exception>()));
    });
  });

  // ── deleteOrder ───────────────────────────────────────────────────────────────
  group('deleteOrder', () {
    test('успешно удаляет', () async {
      when(orderRepo.deleteOrder(1)).thenAnswer((_) async => _order());
      await expectLater(sut.deleteOrder(1), completes);
    });

    test('бросает если заказ не найден', () async {
      when(orderRepo.deleteOrder(99)).thenAnswer((_) async => null);
      expect(() => sut.deleteOrder(99), throwsA(isA<Exception>()));
    });
  });
}