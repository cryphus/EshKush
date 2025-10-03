import '../../utils/SafeLoggingUtils.dart';

class PartnerSettings {
  final int id;
  final int partnerId;
  final String brandingColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerSettings({
    required this.id,
    required this.partnerId,
    required this.brandingColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerSettings.fromJson(Map<String, dynamic> json) {
    print('Преобразование JSON в PartnerSettings:');
    final safeJson = SafeLoggingUtils.sanitizeData(json);
    print('JSON данные: $safeJson');
    
    try {
    return PartnerSettings(
      id: json['id'] as int,
      partnerId: json['partner_id'] as int,
        brandingColor: json['branding_color']?.toString() ?? '#000000',
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
    );
    } catch (e, stackTrace) {
      print('Ошибка при создании PartnerSettings: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'branding_color': brandingColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PartnerSettings copyWith({
    int? id,
    int? partnerId,
    String? brandingColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnerSettings(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      brandingColor: brandingColor ?? this.brandingColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          partnerId == other.partnerId &&
          brandingColor == other.brandingColor &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      partnerId.hashCode ^
      brandingColor.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'PartnerSettings(id: $id, partnerId: $partnerId, brandingColor: $brandingColor, ';
}