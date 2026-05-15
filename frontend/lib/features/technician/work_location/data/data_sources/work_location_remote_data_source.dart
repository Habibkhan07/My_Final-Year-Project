import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/work_location_model.dart';

/// HTTP boundary for the technician work-location endpoint.
///
/// Mirrors the project's standard remote-DS shape: parses 2xx, raises
/// [HttpFailure] for anything else so the repository's
/// switch-on-[HttpFailure.code] mapping can run.
abstract class IWorkLocationRemoteDataSource {
  Future<WorkLocationModel> getWorkLocation();
  Future<WorkLocationModel> patchWorkLocation(Map<String, dynamic> body);
}

class WorkLocationRemoteDataSource implements IWorkLocationRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  static const String _path = '/technicians/me/work-location/';

  WorkLocationRemoteDataSource({
    required this.client,
    required this.authLocalDataSource,
  });

  Uri get _uri => Uri.parse('${AppConstants.baseUrl}$_path');

  Future<Map<String, String>> _headers() async {
    final token = await authLocalDataSource.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  @override
  Future<WorkLocationModel> getWorkLocation() async {
    final response = await client.get(_uri, headers: await _headers());
    _handleResponse(response);
    return WorkLocationModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WorkLocationModel> patchWorkLocation(Map<String, dynamic> body) async {
    final response = await client.patch(
      _uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    return WorkLocationModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message: body['message'] as String? ?? 'An error occurred',
          errors: (body['errors'] as Map<String, dynamic>?) ?? const {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: (body is Map ? (body['detail'] ?? body['error']) : null)
                ?.toString() ??
            'Unknown error',
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
