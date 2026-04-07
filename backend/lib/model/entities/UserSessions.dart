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
  String refreshJtiHash;
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
    required this.refreshJtiHash,
    this.isActive = true,
  }) {
    if (userAgent.isEmpty) throw ArgumentError('User agent cannot be empty');
    if (ipAddress.isEmpty) throw ArgumentError('IP address cannot be empty');
    if (refreshJtiHash.isEmpty) throw ArgumentError('Refresh JTI hash cannot be empty');
    if (expiresAt.isBefore(createdAt)) {
      throw ArgumentError('Expiration date cannot be before creation date');
    }
  }

  factory UserSessions.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'] ?? json['created_at'];
    final expiresRaw = json['expiresAt'] ?? json['expires_at'];
    final lastRaw = json['lastActive'] ?? json['last_active'] ?? createdRaw;
    final ua = json['userAgent'] ?? json['device_info'] ?? '';
    final ip = json['ipAddress'] ?? json['ip_address'] ?? '';
    final statusStr = (json['status'] ?? 'active').toString();
    final statusEnum = SessionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => SessionStatus.active,
    );
    return UserSessions(
      id: int.parse(json['id'].toString()),
      userId: int.parse((json['userId'] ?? json['user_id']).toString()),
      createdAt: DateTime.parse(createdRaw.toString()),
      expiresAt: DateTime.parse(expiresRaw.toString()),
      lastActive: DateTime.parse(lastRaw.toString()),
      userAgent: ua.toString(),
      ipAddress: ip.toString(),
      status: statusEnum,
      deviceId: (json['deviceId'] ?? json['device_id']) as String?,
      location: json['location'] as String?,
      token: json['token'] as String?,
      refreshJtiHash: (json['refreshJtiHash'] ?? json['refresh_jti_hash'] ?? '').toString(),
      isActive: (json['isActive'] as bool?) ?? (statusStr == 'active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'device_info': userAgent,
      'ip_address': ipAddress,
      'status': status.toString().split('.').last,
      'device_id': deviceId,
      'location': location,
      'token': token,
      'refresh_jti_hash': refreshJtiHash,
      'is_active': isActive,
    };
  }

  void updateLastActive() {
    lastActive = DateTime.now();
  }

  void extendSession(Duration duration) {
    expiresAt = expiresAt.add(duration);
  }

  void terminate() {
    status = SessionStatus.revoked;
    isActive = false;
    expiresAt = DateTime.now();
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
  Duration get sessionAge => DateTime.now().difference(createdAt);
  Duration get inactivityDuration => DateTime.now().difference(lastActive);
}