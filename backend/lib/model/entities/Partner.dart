import '../../utils/SafeLoggingUtils.dart';

class Partner {
  final int id;
  final int userId;
  final String name;
  final int contactPerson;
  final String contactEmail;
  final String contactPhone;
  final String contactDocument;
  final double maxDiscount;
  final DateTime createdAt;

  Partner({
    required this.id,
    required this.userId,
    required this.name,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactDocument,
    this.maxDiscount = 0.0,
    required this.createdAt,
  }) {
    _validate();
  }

  void _validate() {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (userId <= 0) {
      throw ArgumentError('User ID must be positive');
    }
  }

  factory Partner.fromJson(Map<String, dynamic> json) {
    print('Преобразование JSON в Partner:');
    final safeJson = SafeLoggingUtils.sanitizeData(json);
    print('JSON данные: $safeJson');
    
    try {
      final partner = Partner(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        name: json['name'] as String,
        contactPerson: json['contact_person'] as int,
        contactEmail: json['contact_email'] as String,
        contactPhone: json['contact_phone'] as String,
        contactDocument: json['contact_document'] as String,
        maxDiscount: (json['max_discount'] is String) 
            ? double.parse(json['max_discount'] as String)
            : (json['max_discount'] as num).toDouble(),
        createdAt: json['created_at'] != null 
            ? (json['created_at'] is DateTime 
                ? json['created_at'] as DateTime 
                : DateTime.parse(json['created_at'] as String))
            : DateTime.now(),
      );
      print('Partner успешно создан');
      return partner;
    } catch (e, stackTrace) {
      print('Ошибка при создании Partner: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'contact_person': contactPerson,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'contact_document': contactDocument,
      'max_discount': maxDiscount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Partner &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          contactEmail == other.contactEmail &&
          contactPhone == other.contactPhone &&
          contactDocument == other.contactDocument &&
          maxDiscount == other.maxDiscount &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      contactEmail.hashCode ^
      contactPhone.hashCode ^
      contactDocument.hashCode ^
      maxDiscount.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'Partner(id: $id, userId: $userId, name: $name, contactEmail: $contactEmail, '
      'contactPhone: $contactPhone, contactDocument: $contactDocument, '
      'maxDiscount: $maxDiscount, createdAt: $createdAt)';
}