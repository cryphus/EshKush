import 'package:backend/model/enums/ActionType.dart';
import 'package:backend/model/enums/EntityType.dart';

class ActionLog {
  final int id;
  final int userId;
  ActionType actionType;
  EntityType targetEntity;
  final int targetId;
  String details;
  DateTime timestamp;
  final String ipAddress;
  String? userAgent;
  String? location;
  bool isSuccess;
  String? errorMessage;
  Map<String, dynamic>? metadata;

  ActionLog({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.targetEntity,
    required this.targetId,
    required this.details,
    required this.timestamp,
    required this.ipAddress,
    this.userAgent,
    this.location,
    this.isSuccess = true,
    this.errorMessage,
    this.metadata,
  }) {
    if (details.isEmpty) throw ArgumentError('Details cannot be empty');
    if (ipAddress.isEmpty) throw ArgumentError('IP address cannot be empty');
  }

  factory ActionLog.fromJson(Map<String, dynamic> json) {
    return ActionLog(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      actionType: ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['action_type'],
        orElse: () => ActionType.other,
      ),
      targetEntity: EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['entity_type'],
        orElse: () => EntityType.other,
      ),
      targetId: json['entity_id'] as int,
      details: json['details'] as String,
      timestamp: json['timestamp'] is DateTime 
          ? json['timestamp'] as DateTime
          : DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String?,
      location: json['location'] as String?,
      isSuccess: json['is_success'] as bool? ?? true,
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType.toString().split('.').last,
      'entity_type': targetEntity.toString().split('.').last,
      'entity_id': targetId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'is_success': isSuccess,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  void markAsFailed(String errorMessage) {
    isSuccess = false;
    this.errorMessage = errorMessage;
  }

  bool get isRecent => DateTime.now().difference(timestamp) < const Duration(hours: 24);
  Duration get age => DateTime.now().difference(timestamp);
}