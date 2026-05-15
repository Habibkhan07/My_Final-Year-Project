import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/technician_status_model.dart';

class TechnicianStatusRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/technicians";
  final AuthLocalDataSource authLocalDataSource;
  final http.Client client;

  /// Hard cap on the status fetch. The endpoint hits one indexed lookup,
  /// so anything past this is a degraded network — not a slow server.
  /// We surface this as a [SocketException] so the repository's existing
  /// offline branch maps it to [TechStatusNetworkFailure] without needing
  /// a separate timeout failure variant.
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// [client] is positional-optional so tests can inject a mock without
  /// changing the call site in the DI graph. Production code omits it
  /// and gets a fresh default [http.Client].
  TechnicianStatusRemoteDataSource(
    this.authLocalDataSource, {
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<TechnicianStatusModel> getMyStatus() async {
    final token = await authLocalDataSource.getToken();
    if (token == null || token.isEmpty) {
      // Short-circuit before the network call: sending
      // ``Authorization: Token `` (empty) would round-trip to a 401 and
      // map to the same failure anyway, but burning an RTT on a known
      // bad request is wasteful on bad coverage.
      throw HttpFailure(
        statusCode: 401,
        code: 'not_authenticated',
        message: 'You are not signed in.',
      );
    }

    final http.Response response;
    try {
      response = await client
          .get(
            Uri.parse('$baseUrl/me/status/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      // Funnel into the SocketException path so the repository's
      // existing handler maps this to NetworkFailure with no special
      // casing on the consumer side.
      throw const SocketException('Request timed out');
    }

    _handleResponse(response);

    return TechnicianStatusModel.fromJson(jsonDecode(response.body));
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'],
          message: body['message'] ?? 'An error occurred',
          errors: body['errors'] ?? {},
        );
      }

      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body['detail'] ?? body['error'] ?? 'Unknown error',
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
