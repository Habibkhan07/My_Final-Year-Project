import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/review_model.dart';

/// HTTP transport for the review endpoints. Mirrors the conventions
/// used by [BookingDetailRemoteDataSource] in this same feature
/// (shared `http.Client`, `Token <token>` auth, `_ensureOk` envelope
/// parser).
///
/// All non-2xx responses throw [HttpFailure] (via `fromEnvelope`); the
/// repository layer is responsible for translating those codes into
/// the sealed [ReviewFailure] hierarchy.
abstract interface class IReviewRemoteDataSource {
  /// `GET /api/bookings/<bookingId>/review/`. Returns the snapshot
  /// model with the existing review (or null) and the predefined tag
  /// dictionary.
  Future<BookingReviewSnapshotModel> fetchSnapshot(int bookingId);

  /// `POST /api/bookings/<bookingId>/review/`. Returns the created
  /// review on 201.
  Future<ReviewModel> submitReview({
    required int bookingId,
    required int rating,
    required List<String> tagKeys,
    required String text,
  });
}

class ReviewRemoteDataSource implements IReviewRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';

  ReviewRemoteDataSource(this._client, this._secureStorage);

  @override
  Future<BookingReviewSnapshotModel> fetchSnapshot(int bookingId) async {
    final token = await _secureStorage.read(key: _tokenKey);
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/review/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    _ensureOk(response);
    return BookingReviewSnapshotModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<ReviewModel> submitReview({
    required int bookingId,
    required int rating,
    required List<String> tagKeys,
    required String text,
  }) async {
    final token = await _secureStorage.read(key: _tokenKey);
    final body = <String, dynamic>{
      'rating': rating,
      'tags': tagKeys,
      // Only send text if non-empty — server accepts empty string but
      // the contract is "optional", and sending empty makes the wire
      // payload look cluttered in logs.
      if (text.trim().isNotEmpty) 'text': text.trim(),
    };
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/review/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    _ensureOk(response);
    return ReviewModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Throws [HttpFailure] on non-2xx. SocketException bubbles to the
  /// repository where it's mapped to [ReviewNetworkFailure].
  ///
  /// Defensive: `HttpFailure.fromEnvelope` tolerates Django error
  /// HTML, non-string code/message values, and missing `errors`
  /// objects. We never assume the body parses as a clean envelope.
  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    throw HttpFailure.fromEnvelope(
      statusCode: response.statusCode,
      body: decoded,
      fallbackMessage: 'Request failed (${response.statusCode}).',
    );
  }
}
