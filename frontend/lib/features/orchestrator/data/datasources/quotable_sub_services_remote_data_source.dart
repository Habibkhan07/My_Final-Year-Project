import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/quotable_sub_service_model.dart';

/// `GET ${baseUrl}/technicians/me/quotable-sub-services/?service_id=N`.
///
/// AppConstants.baseUrl already includes `/api`, so paths start with
/// `/technicians/...`.
abstract interface class IQuotableSubServicesRemoteDataSource {
  Future<List<QuotableSubServiceModel>> fetchForService(int serviceId);
}

class QuotableSubServicesRemoteDataSource
    implements IQuotableSubServicesRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';

  QuotableSubServicesRemoteDataSource(this._client, this._secureStorage);

  @override
  Future<List<QuotableSubServiceModel>> fetchForService(int serviceId) async {
    final token = await _secureStorage.read(key: _tokenKey);
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/technicians/me/quotable-sub-services/',
    ).replace(queryParameters: {'service_id': '$serviceId'});
    final response = await _client.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw HttpFailure(
        statusCode: 502,
        code: 'unexpected_response_shape',
        message: 'Expected a JSON array of sub-services.',
      );
    }
    return decoded
        .map(
          (raw) => QuotableSubServiceModel.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  /// Throws [HttpFailure] on non-2xx. SocketException bubbles up to the
  /// notifier, which surfaces a network-failure state to the sheet.
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
      fallbackMessage: 'Could not load quote catalog (${response.statusCode}).',
    );
  }
}
