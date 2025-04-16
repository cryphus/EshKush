import 'package:backend/model/enums/ActionType.dart';

class OrderActions {
  final int id;
  final int orderId;
  final int partnerId;
  ActionType actionType;
  String actionDescription;
  DateTime actionTimestamp;
  final DateTime? updatedAt;
  bool isActive;

  OrderActions({
    required this.id,
    required this.orderId,
    required this.partnerId,
    required this.actionDescription,
    required this.actionTimestamp,
    this.actionType = ActionType.create,
    this.updatedAt,
    this.isActive = true,
  }) {
    _validate();
  }

  void _validate() {
    if (id <= 0) {
      throw ArgumentError('ID действия должен быть положительным числом');
    }
    if (orderId <= 0) {
      throw ArgumentError('ID заказа должен быть положительным числом');
    }
    if (partnerId <= 0) {
      throw ArgumentError('ID партнера должен быть положительным числом');
    }
    if (actionDescription.isEmpty) {
      throw ArgumentError('Описание действия не может быть пустым');
    }
  }

  void updateActionType(ActionType newType) {
    actionType = newType;
  }

  void updateDescription(String newDescription) {
    if (newDescription.isEmpty) {
      throw ArgumentError('Описание действия не может быть пустым');
    }
    actionDescription = newDescription;
  }

  void deactivate() {
    isActive = false;
  }

  void activate() {
    isActive = true;
  }

  factory OrderActions.fromJson(Map<String, dynamic> json) {
    return OrderActions(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      partnerId: json['partner_id'] as int,
      actionType: ActionType.values.firstWhere(
        (e) => e.toString() == 'ActionType.${json['action_type']}',
        orElse: () => ActionType.create,
      ),
      actionDescription: json['action_description'] as String,
      actionTimestamp: DateTime.parse(json['action_timestamp'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'partner_id': partnerId,
      'action_type': actionType.toString().split('.').last,
      'action_description': actionDescription,
      'action_timestamp': actionTimestamp.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  OrderActions copyWith({
    int? id,
    int? orderId,
    int? partnerId,
    ActionType? actionType,
    String? actionDescription,
    DateTime? actionTimestamp,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return OrderActions(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      partnerId: partnerId ?? this.partnerId,
      actionType: actionType ?? this.actionType,
      actionDescription: actionDescription ?? this.actionDescription,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderActions &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          partnerId == other.partnerId &&
          actionType == other.actionType &&
          actionDescription == other.actionDescription &&
          actionTimestamp == other.actionTimestamp &&
          updatedAt == other.updatedAt &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      partnerId.hashCode ^
      actionType.hashCode ^
      actionDescription.hashCode ^
      actionTimestamp.hashCode ^
      updatedAt.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'OrderActions(id: $id, orderId: $orderId, partnerId: $partnerId, '
      'actionType: $actionType, actionDescription: $actionDescription, '
      'actionTimestamp: $actionTimestamp, isActive: $isActive)';
}