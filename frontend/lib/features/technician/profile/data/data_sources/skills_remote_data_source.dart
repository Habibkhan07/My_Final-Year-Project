import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../models/available_service_model.dart';
import '../models/technician_skill_model.dart';

/// HTTP transport for the tech skills CRUD endpoints.
///
/// Non-2xx responses are parsed into [HttpFailure] using the standard
/// `{status, code, message, errors}` envelope and re-thrown. The
/// repository's `_mapHttp` switch translates the `code` field into
/// a typed [SkillsFailure] subclass.
class SkillsRemoteDataSource {
  final String _techBase = '${AppConstants.baseUrl}/technicians';
  final http.Client _client;

  SkillsRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<TechnicianSkillModel>> listMySkills(String token) async {
    final response = await _client.get(
      Uri.parse('$_techBase/me/skills/'),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(TechnicianSkillModel.fromJson)
        .toList(growable: false);
  }

  Future<TechnicianSkillModel> addSkill({
    required String token,
    required int subServiceId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_techBase/me/skills/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sub_service_id': subServiceId}),
    );
    _handleResponse(response);
    return TechnicianSkillModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> removeSkill({
    required String token,
    required int subServiceId,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_techBase/me/skills/$subServiceId/'),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
    // 204 — no body to parse.
  }

  /// Returns the service tree filtered to the categories the caller
  /// currently works in — derived from the parent services of their
  /// existing ``TechnicianSkill`` rows. The wire shape matches the
  /// onboarding metadata endpoint exactly so the ``AvailableServiceModel``
  /// parser is reused.
  ///
  /// The backend write path (``POST /me/skills/``) enforces the same
  /// gate independently (``category_not_allowed``), so this filter is
  /// defence-in-depth on the FE rather than the sole check.
  Future<List<AvailableServiceModel>> listAvailableServices(
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('$_techBase/me/service-categories/'),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(AvailableServiceModel.fromJson)
        .toList(growable: false);
  }

  /// Mirrors the parser in [ProfileRemoteDataSource] — same envelope
  /// shape, same code/message/errors keys, so the FE error pipeline
  /// is consistent across every authenticated surface.
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
