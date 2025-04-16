import 'package:backend/model/enums/EntityType.dart';
import 'package:backend/model/enums/ChangeType.dart';

class Changes {
  final int id;
  EntityType entityType;
  final int entityId;
  String fieldName;
  String oldValue;
  String newValue;
  final int changedBy;
  DateTime changedAt;
  ChangeType changeType;
  String? comment;
  bool isReverted;
  DateTime? revertedAt;
  int? revertedBy;

  Changes({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.changedAt,
    this.changeType = ChangeType.update,
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
      entityType: EntityType.values.firstWhere(
        (e) => e.toString() == 'EntityType.${json['entityType']}',
        orElse: () => EntityType.other,
      ),
      entityId: json['entityId'] as int,
      fieldName: json['fieldName'] as String,
      oldValue: json['oldValue'] as String,
      newValue: json['newValue'] as String,
      changedBy: json['changedBy'] as int,
      changedAt: DateTime.parse(json['changedAt'] as String),
      changeType: ChangeType.values.firstWhere(
        (e) => e.toString() == 'ChangeType.${json['changeType']}',
        orElse: () => ChangeType.update,
      ),
      comment: json['comment'] as String?,
      isReverted: json['isReverted'] as bool? ?? false,
      revertedAt: json['revertedAt'] != null ? DateTime.parse(json['revertedAt'] as String) : null,
      revertedBy: json['revertedBy'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType.toString().split('.').last,
      'entityId': entityId,
      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedBy': changedBy,
      'changedAt': changedAt.toIso8601String(),
      'changeType': changeType.toString().split('.').last,
      'comment': comment,
      'isReverted': isReverted,
      'revertedAt': revertedAt?.toIso8601String(),
      'revertedBy': revertedBy,
    };
  }

  void revert(int revertedBy, {String? comment}) {
    if (isReverted) throw StateError('Change is already reverted');
    
    isReverted = true;
    this.revertedBy = revertedBy;
    revertedAt = DateTime.now();
    this.comment = comment;
  }

  bool get isRecent => DateTime.now().difference(changedAt) < const Duration(hours: 24);
  Duration get age => DateTime.now().difference(changedAt);
  Duration? get timeToRevert => revertedAt?.difference(changedAt);
}