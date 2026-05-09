import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/address_model.dart';

class AddressRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _baseUrl = '${AppConstants.baseUrl}/customers/addresses/';

  const AddressRemoteDataSource({
    required this.client,
    required this.secureStorage,
  });

  Future<List<CustomerAddressModel>> getAddresses() async {
    final token = await secureStorage.read(key: _tokenKey);
    final response = await client.get(
      Uri.parse(_baseUrl),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => CustomerAddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerAddressModel> saveAddress(CreateAddressRequest request) async {
    final token = await secureStorage.read(key: _tokenKey);
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    _handleResponse(response);
    return CustomerAddressModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CustomerAddressModel> updateAddress(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await secureStorage.read(key: _tokenKey);
    final response = await client.patch(
      Uri.parse('$_baseUrl$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return CustomerAddressModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteAddress(int id) async {
    final token = await secureStorage.read(key: _tokenKey);
    final response = await client.delete(
      Uri.parse('$_baseUrl$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    _handleResponse(response);
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
          errors: (body['errors'] as Map<String, dynamic>?) ?? {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: (body['detail'] ?? body['error'] ?? 'Unknown error')
            .toString(),
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
