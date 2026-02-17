class HttpFailure implements Exception {
  final int statusCode;
  final String code; // Matches "validation_error", "resource_conflict", etc.
  final String message;
  final Map<String, dynamic> errors; // For field-specific validation

  const HttpFailure({
    required this.statusCode,
    required this.code,
    required this.message,
    this.errors = const {},
  });

  @override
  String toString() =>
      'HttpFailure(status: $statusCode, code: $code, message: $message)';
}
