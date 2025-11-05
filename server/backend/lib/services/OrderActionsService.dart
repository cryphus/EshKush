import '../repositories/OrderActionsRepository.dart';
import '../model/entities/OrderActions.dart';
import '../model/enums/ActionType.dart';

class OrderActionsService {
  final OrderActionsRepository _orderActionsRepository;

  OrderActionsService(this._orderActionsRepository);

  Future<OrderActions> getActionById(int id) async {
    try {
      final action = await _orderActionsRepository.findById(id);
      if (action == null) {
        throw Exception('Действие не найдено');
      }
      return action;
    } catch (e) {
      print('Ошибка получения действия: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getOrderActions(int orderId) async {
    try {
      return await _orderActionsRepository.findByOrderId(orderId);
    } catch (e) {
      print('Ошибка получения действий заказа: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getPartnerActions(int partnerId) async {
    try {
      return await _orderActionsRepository.findByPartnerId(partnerId);
    } catch (e) {
      print('Ошибка получения действий партнера: $e');
      rethrow;
    }
  }

  Future<OrderActions> createAction({
    required int orderId,
    required int partnerId,
    required String actionDescription,
    ActionType actionType = ActionType.create,
  }) async {
    try {
      final action = OrderActions(
        id: 0,
        orderId: orderId,
        description: actionDescription,
        createdAt: DateTime.now(),
        actionType: actionType,
      );
      return await _orderActionsRepository.create(action);
    } catch (e) {
      print('Ошибка создания действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> updateAction(OrderActions action) async {
    try {
      return await _orderActionsRepository.update(action);
    } catch (e) {
      print('Ошибка обновления действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> updateActionType(int id, ActionType newType) async {
    try {
      final action = await getActionById(id);
      action.updateActionType(newType);
      return await _orderActionsRepository.update(action);
    } catch (e) {
      print('Ошибка обновления типа действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> updateActionDescription(int id, String newDescription) async {
    try {
      final action = await getActionById(id);
      action.updateDescription(newDescription);
      return await _orderActionsRepository.update(action);
    } catch (e) {
      print('Ошибка обновления описания действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> deactivateAction(int id) async {
    try {
      final action = await getActionById(id);
      // В текущей схеме нет поля активности; интерпретируем как смену типа
      action.updateActionType(ActionType.delete);
      return await _orderActionsRepository.update(action);
    } catch (e) {
      print('Ошибка деактивации действия: $e');
      rethrow;
    }
  }

  Future<OrderActions> activateAction(int id) async {
    try {
      final action = await getActionById(id);
      // Возвращаем к типу create как аналог "активации"
      action.updateActionType(ActionType.create);
      return await _orderActionsRepository.update(action);
    } catch (e) {
      print('Ошибка активации действия: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getActionsByType(ActionType actionType) async {
    try {
      return await _orderActionsRepository.getByActionType(actionType);
    } catch (e) {
      print('Ошибка получения действий по типу: $e');
      rethrow;
    }
  }

  Future<List<OrderActions>> getActiveActions() async {
    try {
      return await _orderActionsRepository.getActiveActions();
    } catch (e) {
      print('Ошибка получения активных действий: $e');
      rethrow;
    }
  }
} 