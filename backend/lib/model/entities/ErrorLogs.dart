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
      errorMessage: json['message'] as String,
      errorCode: json['error_code'] as String,
      stackTrace: json['stack_trace'] as String,
      time: json['time'] is DateTime 
          ? json['time'] as DateTime
          : DateTime.parse(json['time'] as String),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => ErrorSeverity.medium,
      ),
      resolved: json['resolved'] as bool? ?? false,
      module: json['module'] as String?,
      userId: json['user_id'] as int?,
      additionalInfo: json['additional_info'] as String?,
      resolvedAt: json['resolved_at'] != null 
          ? (json['resolved_at'] is DateTime 
              ? json['resolved_at'] as DateTime
              : DateTime.parse(json['resolved_at'] as String))
          : null,
      resolvedBy: json['resolved_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': errorMessage,
      'error_code': errorCode,
      'stack_trace': stackTrace,
      'time': time.toIso8601String(),
      'severity': severity.toString().split('.').last,
      'resolved': resolved,
      'module': module,
      'user_id': userId,
      'additional_info': additionalInfo,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
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