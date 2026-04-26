import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';
import '../../../../core/common/errors/http_failure.dart'; // Import the new exception
import '../../../../core/common/data/models/user_model.dart';
import 'auth_local_data_source.dart';

class AuthRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/accounts";
  final AuthLocalDataSource localDataSource;

  AuthRemoteDataSource(this.localDataSource);

  // --- 1. REQUEST OTP ---
  Future<String> requestOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login-otp/'), // Updated endpoint name per your views
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    // Helper method handles the strict parsing
    _handleResponse(response);

    // If success (200), parse raw data
    final data = jsonDecode(response.body);
    return data['message'] ?? "OTP Sent";
  }

  // --- 2. VERIFY OTP ---
  Future<UserModel> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    _handleResponse(response);

    // If success (200), return the raw user model
    return UserModel.fromJson(jsonDecode(response.body));
  }

  // --- 3. COMPLETE SIGNUP ---
  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  ) async {
    // If token passed is empty, fallback to local storage
    String authToken = token;
    if (authToken.isEmpty) {
        authToken = await localDataSource.getToken() ?? '';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/complete-signup/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
    );

    _handleResponse(response);

    final data = jsonDecode(response.body);
    return data['message'] ?? "Profile updated";
  }

  // --- THE PARSER LOGIC ---
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success, let the caller handle the body
    }

    try {
      final body = jsonDecode(response.body);

      // 1. Check if it matches our Standard Envelope
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'], // e.g., "validation_error"
          message: body['message'] ?? 'An error occurred',
          errors: body['errors'] ?? {},
        );
      }

      // 2. Fallback for legacy/unexpected errors
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body['detail'] ?? body['error'] ?? 'Unknown error',
      );
    } catch (e) {
      if (e is HttpFailure) rethrow;

      // 3. Fallback for non-JSON responses (e.g. 502 Bad Gateway html)
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'server_error',
        message: 'Server error: ${response.statusCode}',
      );
    }
  }
}
