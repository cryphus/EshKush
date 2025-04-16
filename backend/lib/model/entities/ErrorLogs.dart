import 'package:backend/model/enums/ErrorSeverity.dart';

class ErrorLogs {
  final int id;
  final String errorMessage;
  final String errorCode;
  String stackTrace;
  DateTime time;
  bool resolved;
  ErrorSeverity severity;
  String? module;
  int? userId;
  String? additionalInfo;
  DateTime? resolvedAt;
  String? resolvedBy;

  ErrorLogs({
    required this.id,
    required this.errorMessage,
    required this.errorCode,
    required this.stackTrace,
    required this.time,
    required this.severity,
    this.resolved = false,
    this.module,
    this.userId,
    this.additionalInfo,
    this.resolvedAt,
    this.resolvedBy,
  }) {
    if (errorMessage.isEmpty) throw ArgumentError('Error message cannot be empty');
    if (errorCode.isEmpty) throw ArgumentError('Error code cannot be empty');
    if (stackTrace.isEmpty) throw ArgumentError('Stack trace cannot be empty');
  }

  factory ErrorLogs.fromJson(Map<String, dynamic> json) {
    return ErrorLogs(
      id: json['id'] as int,
      errorMessage: json['errorMessage'] as String,
      errorCode: json['errorCode'] as String,
      stackTrace: json['stackTrace'] as String,
      time: DateTime.parse(json['time'] as String),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.toString() == 'ErrorSeverity.${json['severity']}',
        orElse: () => ErrorSeverity.medium,
      ),
      resolved: json['resolved'] as bool? ?? false,
      module: json['module'] as String?,
      userId: json['userId'] as int?,
      additionalInfo: json['additionalInfo'] as String?,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      resolvedBy: json['resolvedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'stackTrace': stackTrace,
      'time': time.toIso8601String(),
      'severity': severity.toString().split('.').last,
      'resolved': resolved,
      'module': module,
      'userId': userId,
      'additionalInfo': additionalInfo,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
    };
  }

  void markAsResolved(String resolvedBy) {
    resolved = true;
    resolvedAt = DateTime.now();
    this.resolvedBy = resolvedBy;
  }

  bool get isCritical => severity == ErrorSeverity.critical;
  bool get isHigh => severity == ErrorSeverity.high;
  bool get isMedium => severity == ErrorSeverity.medium;
  bool get isLow => severity == ErrorSeverity.low;

  Duration get age => DateTime.now().difference(time);
  Duration? get resolutionTime => resolvedAt?.difference(time);
}