import 'package:backend/model/enums/EntityType.dart';
import 'package:backend/model/enums/ChangeType.dart';

class Changes {
  final int id;
  final String entityType;
  final int entityId;
  final String changeType;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final int? changedBy;
  final DateTime createdAt;
  final String? comment;
  final bool isReverted;
  final DateTime? revertedAt;
  final int? revertedBy;

  Changes({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.changeType,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    this.changedBy,
    required this.createdAt,
    this.comment,
    this.isReverted = false,
    this.revertedAt,
    this.revertedBy,
  }) {
    if (fieldName.isEmpty) throw ArgumentError('Field name cannot be empty');
    if (oldValue == newValue) throw ArgumentError('Old and new values cannot be the same');
  }

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      id: json['id'] as int,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      changeType: json['change_type'] as String,
      fieldName: json['field_name'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      changedBy: json['changed_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      comment: json['comment'] as String?,
      isReverted: json['is_reverted'] as bool? ?? false,
      revertedAt: json['reverted_at'] != null ? DateTime.parse(json['reverted_at'] as String) : null,
      revertedBy: json['reverted_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'change_type': changeType,
      'field_name': fieldName,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_by': changedBy,
      'created_at': createdAt.toIso8601String(),
      'comment': comment,
      'is_reverted': isReverted,
      'reverted_at': revertedAt?.toIso8601String(),
      'reverted_by': revertedBy,
    };
  }

  bool get isRecent => DateTime.now().difference(createdAt) < const Duration(hours: 24);
  Duration get age => DateTime.now().difference(createdAt);
}