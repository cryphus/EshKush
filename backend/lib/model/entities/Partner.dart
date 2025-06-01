class Partner {
  final int id;
  String name;
  int contactPerson;
  String concactEmail;
  String contactPhone;
  String contactDocument;
  double maxDiscount;
  DateTime createdAt;

  Partner({
    required this.id,
    required this.name,
    required this.concactEmail,
    required this.contactDocument,
    required this.contactPerson,
    required this.contactPhone,
    required this.createdAt,
    this.maxDiscount = 0.0,
  }) {
    _validate();
  }

  void _validate() {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (contactPerson <= 0) {
      throw ArgumentError('Contact person ID must be positive');
    }
    if (maxDiscount < 0 || maxDiscount > 100) {
      throw ArgumentError('Max discount must be between 0 and 100');
    }
  }

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as int,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as int,
      concactEmail: json['contact_email'] as String,
      contactPhone: json['contact_phone'] as String,
      contactDocument: json['contact_document'] as String,
      maxDiscount: (json['max_discount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'contact_email': concactEmail,
      'contact_phone': contactPhone,
      'contact_document': contactDocument,
      'max_discount': maxDiscount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  void updateName(String newName) {
    if (newName.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    name = newName;
  }

  void updateMaxDiscount(double newDiscount) {
    if (newDiscount < 0 || newDiscount > 100) {
      throw ArgumentError('Max discount must be between 0 and 100');
    }
    maxDiscount = newDiscount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Partner &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          contactPerson == other.contactPerson &&
          concactEmail == other.concactEmail &&
          contactPhone == other.contactPhone &&
          contactDocument == other.contactDocument &&
          maxDiscount == other.maxDiscount &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      contactPerson.hashCode ^
      concactEmail.hashCode ^
      contactPhone.hashCode ^
      contactDocument.hashCode ^
      maxDiscount.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'Partner(id: $id, name: $name, contactPerson: $contactPerson, '
      'contactEmail: $concactEmail, contactPhone: $contactPhone, '
      'contactDocument: $contactDocument, maxDiscount: $maxDiscount, '
      'createdAt: $createdAt)';
}