import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/system_event_model.dart';

/// Remote calls for the event sync + FCM device-registration endpoints.
///
/// This class does not wrap errors — it follows the project's 4-step error
/// pipeline: non-2xx responses are parsed into the project's standard error
/// envelope and re-thrown as [HttpFailure]. The Repository is responsible
/// for mapping [HttpFailure] to Domain sealed classes.
///
/// Auth: DRF TokenAuthentication (`Authorization: Token <t>`). The token is
/// read per call from [FlutterSecureStorage] under [_tokenKey]. There is no
/// global auth interceptor in this project.
class EventRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  /// Applied to every HTTP call in this data source. On elapse, the
  /// underlying `Future` throws [TimeoutException] — the repository's catch
  /// branch relies on this type being thrown.
  static const _timeout = Duration(seconds: 10);

  static const _tokenKey = 'auth_token';
  static const _eventsUrl = '${AppConstants.baseUrl}/events';
  static const _devicesUrl = '${AppConstants.baseUrl}/devices';

  const EventRemoteDataSource({
    required http.Client client,
    required FlutterSecureStorage secureStorage,
  })  : _client = client,
        _secureStorage = secureStorage;

  /// `GET /api/events/sync/?since=<iso>&limit=<n>` — fetch events missed
  /// while the WebSocket was disconnected.
  ///
  /// Throws [HttpFailure] on any non-2xx response.
  Future<List<SystemEventModel>> fetchEventsSince(
    String isoTimestamp, {
    int limit = 50,
  }) async {
    final uri = Uri.parse('$_eventsUrl/sync/').replace(
      queryParameters: {'since': isoTimestamp, 'limit': '$limit'},
    );
    final response = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    _handleResponse(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => SystemEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/events/unacknowledged/` — fetch critical events the user
  /// has not yet acknowledged (reloaded on every cold start).
  ///
  /// Throws [HttpFailure] on any non-2xx response.
  Future<List<SystemEventModel>> fetchUnacknowledgedCritical() async {
    final uri = Uri.parse('$_eventsUrl/unacknowledged/');
    final response = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    _handleResponse(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => SystemEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/events/ack/` with body `{"event_ids": [...]}`.
  /// Backend returns 204 on success.
  ///
  /// Throws [HttpFailure] on any non-2xx response.
  Future<void> acknowledgeEvents(List<String> eventIds) async {
    final uri = Uri.parse('$_eventsUrl/ack/');
    final response = await _client
        .post(
          uri,
          headers: await _authHeaders(contentType: true),
          body: jsonEncode({'event_ids': eventIds}),
        )
        .timeout(_timeout);
    _handleResponse(response);
  }

  /// `POST /api/devices/register/` — register an FCM device token.
  ///
  /// Throws [HttpFailure] on any non-2xx response.
  Future<void> registerDevice(String token, String deviceType) async {
    final uri = Uri.parse('$_devicesUrl/register/');
    final response = await _client
        .post(
          uri,
          headers: await _authHeaders(contentType: true),
          body: jsonEncode({
            'device_token': token,
            'device_type': deviceType,
          }),
        )
        .timeout(_timeout);
    _handleResponse(response);
  }

  /// `POST /api/devices/unregister/` — deregister an FCM device token.
  ///
  /// Throws [HttpFailure] on any non-2xx response.
  Future<void> unregisterDevice(String token) async {
    final uri = Uri.parse('$_devicesUrl/unregister/');
    final response = await _client
        .post(
          uri,
          headers: await _authHeaders(contentType: true),
          body: jsonEncode({'device_token': token}),
        )
        .timeout(_timeout);
    _handleResponse(response);
  }

  Future<Map<String, String>> _authHeaders({bool contentType = false}) async {
    final token = await _secureStorage.read(key: _tokenKey) ?? '';
    return {
      'Authorization': 'Token $token',
      if (contentType) 'Content-Type': 'application/json',
    };
  }

  /// Parses the project's standard error envelope and throws [HttpFailure]
  /// on any non-2xx response. Mirrors the helper used by the existing
  /// `AddressRemoteDataSource` so error shape stays consistent.
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message:
              body['message'] as String? ?? 'An error occurred',
          errors: (body['errors'] as Map<String, dynamic>?) ?? const {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body is Map<String, dynamic>
            ? (body['detail'] ?? body['error'] ?? 'Unknown error').toString()
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
