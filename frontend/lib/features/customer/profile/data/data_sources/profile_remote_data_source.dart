import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../models/customer_profile_model.dart';

/// HTTP transport for `/api/accounts/me/`.
///
/// Non-2xx responses are parsed into [HttpFailure] using the standard
/// error envelope ({status, code, message, errors}) and re-thrown. The
/// repository's `_mapFailures` switch translates `code` into the
/// domain's sealed `ProfileFailure` subclass.
class ProfileRemoteDataSource {
  final String _baseUrl = '${AppConstants.baseUrl}/accounts';
  final http.Client _client;

  ProfileRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  Future<CustomerProfileModel> getMe(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/me/'),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
    return CustomerProfileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CustomerProfileModel> updateMe({
    required String token,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/me/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
    );
    _handleResponse(response);
    return CustomerProfileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Mirrors the parser in [AuthRemoteDataSource] — same envelope shape,
  /// same code/message/errors keys, so the FE error pipeline is
  /// consistent across every authenticated surface.
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message: body['message'] as String? ?? 'An error occurred',
          errors: (body['errors'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: (body is Map ? body['detail'] : null) as String? ??
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
