class PartnerSettings {
  final int id;
  final int partnerId;
  //
  String brandingColor;
  //
  DateTime createdAt;
  DateTime updatedAt;

  PartnerSettings({
    required this.id,
    required this.partnerId,
    required this.brandingColor,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validate();
  }

  void _validate() {
    if (id <= 0) {
      throw ArgumentError('ID настроек должен быть положительным числом');
    }
    if (partnerId <= 0) {
      throw ArgumentError('ID партнера должен быть положительным числом');
    }
    if (!_isValidColor(brandingColor)) {
      throw ArgumentError('Неверный формат цвета');
    }
  }

  bool _isValidColor(String color) {
    final colorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return colorRegex.hasMatch(color);
  }

  void updateBrandingColor(String newColor) {
    if (!_isValidColor(newColor)) {
      throw ArgumentError('Неверный формат цвета');
    }
    brandingColor = newColor;
    updatedAt = DateTime.now();
  }


  factory PartnerSettings.fromJson(Map<String, dynamic> json) {
    return PartnerSettings(
      id: json['id'] as int,
      partnerId: json['partner_id'] as int,
      brandingColor: json['branding_color'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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