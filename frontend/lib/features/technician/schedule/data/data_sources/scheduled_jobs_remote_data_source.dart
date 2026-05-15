// Wire-level entry point for the tech-side scheduled-jobs endpoints.
//
// Throws [HttpFailure] (parsed from the standard error envelope) for
// any non-2xx response. Lets [SocketException] propagate so the
// repository can map it to the offline path. Mirrors the customer-side
// `CustomerBookingsRemoteDataSource` so the repository's `_mapHttpFailure`
// switch keys off the same envelope shape across both features.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/scheduled_job_segment.dart';
import '../models/scheduled_jobs_counts_model.dart';
import '../models/scheduled_jobs_list_response_model.dart';

abstract class IScheduledJobsRemoteDataSource {
  /// `GET /api/technicians/me/scheduled-jobs/?segment=…&cursor=…&page_size=…`
  Future<ScheduledJobsListResponseModel> getScheduledJobs({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  });

  /// `GET /api/technicians/me/scheduled-jobs/counts/`
  Future<ScheduledJobsCountsModel> getCounts();
}

class ScheduledJobsRemoteDataSource implements IScheduledJobsRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  /// Matches the key written by `AuthLocalDataSource`. Same convention
  /// every other authenticated remote data source in the codebase uses.
  static const String _tokenKey = 'auth_token';

  ScheduledJobsRemoteDataSource({
    required this.client,
    required this.secureStorage,
  });

  @override
  Future<ScheduledJobsListResponseModel> getScheduledJobs({
    required ScheduledJobSegment segment,
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
      // csv form — the backend serializer doesn't accept Django's
      // repeated-key list form.
      params['status'] = statusFilter
          .map((s) => s.wireValue)
          .where((s) => s.isNotEmpty)
          .join(',');
    }

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/technicians/me/scheduled-jobs/',
    ).replace(queryParameters: params);

    final response = await _authedGet(uri);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ScheduledJobsListResponseModel.fromJson(json);
  }

  @override
  Future<ScheduledJobsCountsModel> getCounts() async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/technicians/me/scheduled-jobs/counts/',
    );
    final response = await _authedGet(uri);
    _handleResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ScheduledJobsCountsModel.fromJson(json);
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
  /// field. Same shape as `CustomerBookingsRemoteDataSource`.
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
