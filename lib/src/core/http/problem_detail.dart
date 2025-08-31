// DIDACTIC: RFC-7807 Problem Detail parser
//
// Purpose:
// - Parse server error responses conforming (or similar) to RFC-7807 into a
//   local `ProblemDetail` instance so UI layers and services can provide
//   user-friendly messages and programmatic error handling.
//
// Contract:
// - Input: a `Map<String, dynamic>` typically received from the HTTP layer.
// - Output: a `ProblemDetail` instance that implements `Exception`.
// - Error modes: parsing is defensive; unknown or missing fields fall back to
//   reasonable defaults so callers can still display an error text.
//
// Notes:
// - Validation errors (list of field messages) are surfaced in `toString()`
//   so SnackBars and dialogs prefer direct user-facing messages.

class ProblemDetail implements Exception {
  ProblemDetail({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    required this.instance,
    this.timestamp,
    this.error,
    this.path,
    this.code,
    this.validationErrors,
  });

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final String? timestamp;
  final String? error;
  final String? path;
  final String? code;
  final List<Map<String, dynamic>>? validationErrors; // [{field, message}]

  factory ProblemDetail.fromJson(Map<String, dynamic> json) {
    return ProblemDetail(
      type: json['type'] as String?,
      title: json['title'] as String?,
      status: (json['status'] as num?)?.toInt(),
      detail: json['detail'] as String?,
      instance: json['instance'] as String?,
      timestamp: json['timestamp']?.toString(),
      error: json['error']?.toString(),
      path: json['path']?.toString(),
      code: json['code']?.toString(),
      validationErrors: (json['errors'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList(),
    );
  }

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      final first = validationErrors!.first;
      return first['message']?.toString() ?? title ?? 'Erro';
    }
    return title ?? detail ?? error ?? 'Erro';
  }
}

