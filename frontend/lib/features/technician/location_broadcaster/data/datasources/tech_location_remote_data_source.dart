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
import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

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

    final http.Response response;
    try {
      // Audit H3 (F-19/T-7d): a hung POST blocks the foreground task's
      // serial executor — Geolocator keeps producing fixes that queue
      // behind the in-flight call, and the customer sees "tech offline"
      // after 60s even though GPS is working. 8s is well above the
      // p99 mobile-network round-trip and well below the customer's
      // staleness threshold.
      response = await _client
          .post(
            Uri.parse(
              '${AppConstants.baseUrl}/bookings/$bookingId/tech-location/',
            ),
            headers: {
              'Authorization': 'Token $authToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw HttpFailure(
        statusCode: 0,
        code: 'network_timeout',
        message: 'tech-location POST timed out',
        errors: const {},
      );
    } on SocketException {
      throw HttpFailure(
        statusCode: 0,
        code: 'network_failure',
        message: 'tech-location POST: network unreachable',
        errors: const {},
      );
    }

    if (response.statusCode == 200) return true;
    if (response.statusCode == 429) return false; // throttled — drop silently

    // Audit S-14 (Batch B): defensive parse via HttpFailure.fromEnvelope
    // — coerces non-string code/message and tolerates non-JSON bodies
    // (HTML 502 from a load balancer, mistyped fields from a server
    // bug). Pre-fix the inline `as String?` cast threw `TypeError` on
    // any shape drift, bubbling out of the isolate's narrow catch.
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    throw HttpFailure.fromEnvelope(
      statusCode: response.statusCode,
      body: decoded,
      fallbackMessage:
          'tech-location POST failed (${response.statusCode})',
    );
  }
}
