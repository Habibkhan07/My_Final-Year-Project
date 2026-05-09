// SECURITY: tech-only POST endpoint. The backend gates by tech_profile +
// assigned-tech IDOR + 4-second per-(tech_user_id, booking_id) throttle.
// 401 if missing token; 403 if not the assigned tech; 429 on throttle.
// Auth is `Authorization: Token <token_key>` (DRF TokenAuthentication —
// same token issued by REST login; the WebSocket uses the same token via
// its query string).
//
// Per audit P0-03 + sprint meta §24: package:http only, no Dio. URL
// concatenation does NOT add `/api/` because AppConstants.baseUrl
// already terminates in `/api`.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../models/tech_location_request_model.dart';

class TechLocationRemoteDataSource {
  final http.Client _client;
  TechLocationRemoteDataSource(this._client);

  /// POSTs a single GPS frame.
  ///
  /// Returns `true` when the backend accepted (200 published / 200
  /// silent no-op on terminal status both count as accepted from the
  /// client's perspective). Returns `false` on a 429 throttle response
  /// — the foreground task handler treats this as "drop the frame, no
  /// error" since the client cadence (5s) sometimes outruns the
  /// backend's 4s window due to clock drift.
  ///
  /// Throws [HttpFailure] on any other 4xx/5xx so call-sites can log
  /// and the supervisor (the controller) can decide whether to surface
  /// a permission-denied / not-the-tech error in the UI.
  Future<bool> postLocation({
    required int bookingId,
    required String authToken,
    required double lat,
    required double lng,
    double? accuracyMeters,
    double? heading,
  }) async {
    final body = TechLocationRequestModel(
      lat: lat,
      lng: lng,
      accuracyMeters: accuracyMeters,
      heading: heading,
    ).toJson();

    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/tech-location/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) return true;
    if (response.statusCode == 429) return false; // throttled — drop silently

    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } catch (_) {
      // Server returned non-JSON (HTML 502 page from a load balancer,
      // for instance). Fall through to the generic envelope shape.
    }

    throw HttpFailure(
      statusCode: response.statusCode,
      code: envelope?['code'] as String? ?? 'unknown',
      message:
          envelope?['message'] as String? ??
          'tech-location POST failed (${response.statusCode})',
      errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
