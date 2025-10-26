import '../../entities/Partner.dart';

class PartnerResponseDto {
  final int id;
  final int userId;
  final String name;
  final String contactEmail;
  final String contactPhone;
  final double maxDiscount;
  final DateTime createdAt;

  PartnerResponseDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.contactEmail,
    required this.contactPhone,
    required this.maxDiscount,
    required this.createdAt,
  });

  factory PartnerResponseDto.fromEntity(Partner partner) {
    return PartnerResponseDto(
      id: partner.id,
      userId: partner.userId,
      name: partner.name,
      contactEmail: partner.contactEmail,
      contactPhone: partner.contactPhone,
      maxDiscount: partner.maxDiscount,
      createdAt: partner.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'max_discount': maxDiscount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PartnerAdminDto {
  final int id;
  final int userId;
  final String name;
  final int contactPerson;
  final String contactEmail;
  final String contactPhone;
  final String contactDocument;
  final double maxDiscount;
  final DateTime createdAt;

  PartnerAdminDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactDocument,
    required this.maxDiscount,
    required this.createdAt,
  });

  factory PartnerAdminDto.fromEntity(Partner partner) {
    return PartnerAdminDto(
      id: partner.id,
      userId: partner.userId,
      name: partner.name,
      contactPerson: partner.contactPerson,
      contactEmail: partner.contactEmail,
      contactPhone: partner.contactPhone,
      contactDocument: partner.contactDocument,
      maxDiscount: partner.maxDiscount,
      createdAt: partner.createdAt,
    );
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
}
