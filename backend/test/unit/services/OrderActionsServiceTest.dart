import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OrderActionsService.dart';
import 'package:backend/repositories/OrderActionsRepository.dart';
import 'package:backend/model/entities/OrderActions.dart';
import 'package:backend/model/enums/ActionType.dart';

import 'OrderActionsServiceTest.mocks.dart';

@GenerateMocks([OrderActionsRepository])
void main() {
  late MockOrderActionsRepository repo;
  late OrderActionsService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockOrderActionsRepository();
    sut  = OrderActionsService(repo);
  });

  OrderActions _action({int id = 1, ActionType type = ActionType.create}) =>
      OrderActions(
        id: id, orderId: 1,
        actionType: type,
        description: 'test action',
        createdAt: DateTime(2024),
      );

  // ── getActionById ──────────────────────────────────────────────────────────
  group('getActionById', () {
    test('возвращает действие по id', () async {
      when(repo.findById(1)).thenAnswer((_) async => _action());
      final result = await sut.getActionById(1);
      expect(result.id, 1);
    });

    test('бросает если действие не найдено', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getActionById(99), throwsA(isA<Exception>()));
    });
  });

  // ── createAction ───────────────────────────────────────────────────────────
  group('createAction', () {
    test('создаёт действие с типом create', () async {
      when(repo.create(any)).thenAnswer((_) async => _action());
      final result = await sut.createAction(
        orderId: 1,
        partnerId: 1,
        actionDescription: 'Created order',
      );
      expect(result.actionType, ActionType.create);
    });
  });

  // ── deactivateAction ───────────────────────────────────────────────────────
  group('deactivateAction', () {
    test('устанавливает тип ActionType.delete', () async {
      when(repo.findById(1)).thenAnswer((_) async => _action());
      when(repo.update(any)).thenAnswer((inv) async {
        final updated = inv.positionalArguments[0] as OrderActions;
        return updated;
      });
      final result = await sut.deactivateAction(1);
      expect(result.actionType, ActionType.delete);
    });

    test('бросает если действие не найдено', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.deactivateAction(99), throwsA(isA<Exception>()));
    });
  });

  // ── activateAction ─────────────────────────────────────────────────────────
  group('activateAction', () {
    test('устанавливает тип ActionType.create', () async {
      when(repo.findById(1)).thenAnswer((_) async => _action(type: ActionType.delete));
      when(repo.update(any)).thenAnswer((inv) async {
        final updated = inv.positionalArguments[0] as OrderActions;
        return updated;
      });
      final result = await sut.activateAction(1);
      expect(result.actionType, ActionType.create);
    });
  });

  // ── getOrderActions ────────────────────────────────────────────────────────
  group('getOrderActions', () {
    test('возвращает действия заказа', () async {
      when(repo.findByOrderId(1)).thenAnswer((_) async => [_action(), _action(id: 2)]);
      final result = await sut.getOrderActions(1);
      expect(result.length, 2);
    });
  });

  // ── getActionsByType ───────────────────────────────────────────────────────
  group('getActionsByType', () {
    test('возвращает действия по типу', () async {
      when(repo.getByActionType(ActionType.create))
          .thenAnswer((_) async => [_action()]);
      final result = await sut.getActionsByType(ActionType.create);
      expect(result.length, 1);
    });
  });
}
