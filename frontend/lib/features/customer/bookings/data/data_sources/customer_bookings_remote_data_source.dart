// Wire-level entry point for the customer bookings list + counts
// endpoints.
//
// Throws [HttpFailure] (parsed from the standard error envelope) for
// any non-2xx response. Lets [SocketException] propagate so the
// repository can map it to the offline path. Mirrors the patterns of
// `IncomingJobRemoteDataSource` so the repository's `_mapFailure`
// switch keys off the same envelope shape across both features.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../domain/entities/booking_segment.dart';
import '../../domain/entities/booking_status.dart';
import '../models/bookings_counts_model.dart';
import '../models/bookings_list_response_model.dart';

abstract class ICustomerBookingsRemoteDataSource {
  /// `GET /api/bookings/?segment=…&cursor=…&page_size=…`
  Future<BookingsListResponseModel> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  });

  /// `GET /api/bookings/counts/`
  Future<BookingsCountsModel> getCounts();
}

class CustomerBookingsRemoteDataSource
    implements ICustomerBookingsRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  /// Matches the key written by `AuthLocalDataSource`. Same convention
  /// every other authenticated remote data source in the codebase uses.
  static const String _tokenKey = 'auth_token';

  CustomerBookingsRemoteDataSource({
    required this.client,
    required this.secureStorage,
  });

  @override
  Future<BookingsListResponseModel> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'segment': segment.wireValue,
      'page_size': pageSize.toString(),
    };
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      // The backend accepts a csv string for this param; sending it as
      // a list would force the wire shape into Django's repeated-key
      // form, which the serializer doesn't accept.
      params['status'] = statusFilter
          .map((s) => s.wireValue)
          .where((s) => s.isNotEmpty)
          .join(',');
    }

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/bookings/',
    ).replace(queryParameters: params);

    final response = await _authedGet(uri);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingsListResponseModel.fromJson(json);
  }

  @override
  Future<BookingsCountsModel> getCounts() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/counts/');
    final response = await _authedGet(uri);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingsCountsModel.fromJson(json);
  }

  Future<http.Response> _authedGet(Uri uri) async {
    final token = await secureStorage.read(key: _tokenKey);
    return client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );
  }

  /// Maps a non-2xx [http.Response] to an [HttpFailure].
  ///
  /// Prefers the server's standard envelope (`{status, code, message,
  /// errors}`) when present; falls back to a synthetic `server_error`
  /// failure when the body is not JSON or doesn't include a `code`
  /// field. Mirrors the helper in `IncomingJobRemoteDataSource`.
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
