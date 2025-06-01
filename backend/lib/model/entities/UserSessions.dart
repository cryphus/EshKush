import 'package:backend/model/enums/SessionStatus.dart';

class UserSessions {
  final int id;
  final int userId;
  //
  final DateTime createdAt;
  DateTime expiresAt;
  DateTime lastActive;
  String userAgent;
  final String ipAddress;
  SessionStatus status;
  String? deviceId;
  String? location;
  String? token;
  bool isActive;

  UserSessions({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActive,
    required this.userAgent,
    required this.ipAddress,
    this.status = SessionStatus.active,
    this.deviceId,
    this.location,
    this.token,
    this.isActive = true,
  }) {
    if (userAgent.isEmpty) throw ArgumentError('User agent cannot be empty');
    if (ipAddress.isEmpty) throw ArgumentError('IP address cannot be empty');
    if (expiresAt.isBefore(createdAt)) {
      throw ArgumentError('Expiration date cannot be before creation date');
    }
  }

  factory UserSessions.fromJson(Map<String, dynamic> json) {
    return UserSessions(
      id: json['id'] as int,
      userId: json['userId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      userAgent: json['userAgent'] as String,
      ipAddress: json['ipAddress'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${json['status']}',
        orElse: () => SessionStatus.active,
      ),
      deviceId: json['deviceId'] as String?,
      location: json['location'] as String?,
      token: json['token'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'status': status.toString().split('.').last,
      'deviceId': deviceId,
      'location': location,
      'token': token,
      'isActive': isActive,
    };
  }

  void updateLastActive() {
    lastActive = DateTime.now();
  }

  void extendSession(Duration duration) {
    expiresAt = expiresAt.add(duration);
  }

  void terminate() {
    status = SessionStatus.terminated;
    isActive = false;
    expiresAt = DateTime.now();
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
  Duration get sessionAge => DateTime.now().difference(createdAt);
  Duration get inactivityDuration => DateTime.now().difference(lastActive);
}