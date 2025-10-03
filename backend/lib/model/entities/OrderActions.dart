import 'package:backend/model/enums/ActionType.dart';

class OrderActions {
  final int id;
  final int orderId;
  ActionType actionType;
  String? description;
  DateTime createdAt;

  OrderActions({
    required this.id,
    required this.orderId,
    this.actionType = ActionType.create,
    this.description,
    required this.createdAt,
  }) {
    _validate();
  }

  void _validate() {
    if (id < 0) {
      throw ArgumentError('ID действия должен быть неотрицательным числом');
    }
    if (orderId <= 0) {
      throw ArgumentError('ID заказа должен быть положительным числом');
    }
  }

  void updateActionType(ActionType newType) {
    actionType = newType;
  }

  void updateDescription(String newDescription) {
    description = newDescription;
  }

  factory OrderActions.fromJson(Map<String, dynamic> json) {
    final rawType = json['action_type']?.toString();
    final parsedType = ActionType.values.firstWhere(
      (e) => e.toString() == 'ActionType.$rawType',
      orElse: () => ActionType.create,
    );

    final createdRaw = json['created_at'];
    final createdAt = createdRaw is DateTime
        ? createdRaw
        : (DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now());

    return OrderActions(
      id: int.parse(json['id'].toString()),
      orderId: int.parse(json['order_id'].toString()),
      actionType: parsedType,
      description: json['description']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'action_type': actionType.toString().split('.').last,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  OrderActions copyWith({
    int? id,
    int? orderId,
    ActionType? actionType,
    String? description,
    DateTime? createdAt,
  }) {
    return OrderActions(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderActions &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          actionType == other.actionType &&
          description == other.description &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      actionType.hashCode ^
      (description?.hashCode ?? 0) ^
      createdAt.hashCode;

  @override
  String toString() =>
      'OrderActions(id: $id, orderId: $orderId, actionType: $actionType, description: $description, createdAt: $createdAt)';
}