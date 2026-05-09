import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';

/// Wire-level entry-point for the technician's accept/decline endpoints.
///
/// Throws [HttpFailure] (parsed from the standard error envelope) for any
/// non-2xx response. Lets [SocketException] propagate so the repository
/// can map it to [IncomingJobNetworkFailure]. Mirrors the conventions of
/// `BookingRemoteDataSource` so the repository's `_mapFailure` switch keys
/// off the same envelope shape across both features.
abstract class IIncomingJobRemoteDataSource {
  /// `POST /api/bookings/{jobId}/accept/`  (empty body)
  Future<void> acceptJobRequest(int jobId);

  /// `POST /api/bookings/{jobId}/decline/` (empty body)
  Future<void> declineJobRequest(int jobId);
}

class IncomingJobRemoteDataSource implements IIncomingJobRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  /// Matches the key written by `AuthLocalDataSource`.
  static const String _tokenKey = 'auth_token';

  IncomingJobRemoteDataSource({
    required this.client,
    required this.secureStorage,
  });

  @override
  Future<void> acceptJobRequest(int jobId) =>
      _postEmpty('${AppConstants.baseUrl}/bookings/$jobId/accept/');

  @override
  Future<void> declineJobRequest(int jobId) =>
      _postEmpty('${AppConstants.baseUrl}/bookings/$jobId/decline/');

  /// POSTs an empty JSON body with the auth header and converts non-2xx
  /// responses to [HttpFailure]. The endpoints both have empty request
  /// bodies (booking id rides the URL; technician identity comes from auth)
  /// so a single helper covers both.
  Future<void> _postEmpty(String url) async {
    final token = await secureStorage.read(key: _tokenKey);
    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode(const <String, dynamic>{}),
    );
    _handleResponse(response);
  }

  /// Maps a non-2xx [http.Response] to an [HttpFailure].
  ///
  /// Prefers the server's standard envelope (`{status, code, message,
  /// errors}`) when present; falls back to a synthetic `server_error`
  /// failure when the body is not JSON or doesn't include a `code` field.
  /// Mirrors the helper in `BookingRemoteDataSource` so the repository's
  /// `_mapFailure` can switch on the same shape across the codebase.
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message: (body['message'] as String?) ?? 'An error occurred',
          errors: (body['errors'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body is Map
            ? (body['detail']?.toString() ??
                  body['error']?.toString() ??
                  'Unknown error')
            : 'Unknown error',
      );
    } catch (e) {
      if (e is HttpFailure) rethrow;
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'server_error',
        message: 'Server error: ${response.statusCode}',
      );
    }
  }
}
