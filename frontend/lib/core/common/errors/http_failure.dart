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

  /// Audit S-14 (Batch B): defensive constructor for "decode whatever
  /// the server sent, fall back to `unknown` on shape drift." Pre-fix,
  /// every data-source pasted the same `envelope?['code'] as String?`
  /// pattern — which throws `TypeError` if the server ever returns a
  /// numeric `code` (e.g. `42`) or a non-string `message`. Coerce to
  /// string via `toString()`, accept any `Map` shape for `errors`,
  /// and never throw in the parse path. The thrown failure object
  /// itself stays the same; only the parser is hardened.
  ///
  /// `statusCode` is required because callers know it from the HTTP
  /// response; everything else is best-effort from the body.
  factory HttpFailure.fromEnvelope({
    required int statusCode,
    required Object? body,
    String fallbackCode = 'unknown',
    String? fallbackMessage,
  }) {
    // HF-1 (Batch I): broaden the Map-shape check. `jsonDecode`
    // typically returns `Map<String, dynamic>` for object literals,
    // but some decoders / pre-decoded paths produce
    // `Map<dynamic, dynamic>`. The strict `is Map<String, dynamic>`
    // rejected the latter and silently fell through to the fallback
    // envelope, losing every error key the server actually sent.
    Map<String, dynamic>? envelope;
    if (body is Map) {
      envelope = body.cast<String, dynamic>();
    }

    final rawCode = envelope?['code'];
    final code = rawCode == null ? fallbackCode : rawCode.toString();

    final rawMessage = envelope?['message'];
    final message = rawMessage == null
        ? (fallbackMessage ?? 'request failed ($statusCode)')
        : rawMessage.toString();

    // HF-2 (Batch I): same broadening on `errors`. Backend may emit
    // `Map<String, List<String>>` (DRF's per-field validation list
    // shape) which fails the narrow `Map<String, dynamic>` check.
    // `Map.cast` returns a view; the wrapping is correct because
    // every concrete `Map` from `jsonDecode` has String keys.
    final rawErrors = envelope?['errors'];
    final errors = rawErrors is Map
        ? rawErrors.cast<String, dynamic>()
        : <String, dynamic>{};

    return HttpFailure(
      statusCode: statusCode,
      code: code,
      message: message,
      errors: errors,
    );
  }

  @override
  String toString() =>
      'HttpFailure(status: $statusCode, code: $code, message: $message)';
}
