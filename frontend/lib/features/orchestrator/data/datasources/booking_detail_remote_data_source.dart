import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/booking_detail_model.dart';

/// `GET ${baseUrl}/bookings/<id>/`. AppConstants.baseUrl already
/// includes `/api`, so the path here MUST start with `/bookings/...`,
/// not `/api/bookings/...` (sprint §24 + audit C2-P0-01).
abstract interface class IBookingDetailRemoteDataSource {
  Future<BookingDetailModel> fetch(int bookingId);
}

class BookingDetailRemoteDataSource implements IBookingDetailRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';

  BookingDetailRemoteDataSource(this._client, this._secureStorage);

  @override
  Future<BookingDetailModel> fetch(int bookingId) async {
    final token = await _secureStorage.read(key: _tokenKey);
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    _ensureOk(response);
    return BookingDetailModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Throws [HttpFailure] on non-2xx; SocketException bubbles to the
  /// repository layer where it's mapped to BookingDetailOfflineNoCache
  /// (no cache) or returns the cached entity (offline-first).
  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } catch (_) {
      // Non-JSON body (e.g. Django HTML error page). Fall through to
      // generic message — the failure is still surfaced.
    }
    throw HttpFailure(
      statusCode: response.statusCode,
      code: envelope?['code'] as String? ?? 'unknown',
      message:
          envelope?['message'] as String? ??
          'Request failed (${response.statusCode}).',
      errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
