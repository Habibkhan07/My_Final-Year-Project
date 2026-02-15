import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart'; // Import your constants
import '../../../../core/common/data/models/user_model.dart';

class AuthRemoteDataSource {
  // Use the constant instead of a hardcoded string
  final String baseUrl = "${AppConstants.baseUrl}/accounts";

  Future<String> requestOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      // We parse the JSON body to find the message key
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['message'] ?? "OTP Sent";
      // auth_remote_data_source.dart
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final errorMessage = errorData['phone']?[0] ?? "Request failed";

      // REMOVE 'Exception()' and throw the raw string
      throw "${response.statusCode}: $errorMessage";
    }
  }
  // auth_remote_data_source.dart

  Future<UserModel> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      // 1. Decode the response body
      final Map<String, dynamic> errorData = jsonDecode(response.body);

      // 2. Extract the specific "error" key from your AuthService
      final errorMessage = errorData['error'] ?? "Verification failed";

      // 3. Throw a structured exception that includes the status code
      throw "${response.statusCode}: $errorMessage";
    }
  }

  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complete-signup/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token', // Django Token Auth requirement
      },
      body: jsonEncode({'first_name': firstName, 'last_name': lastName}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? "Profile updated";
    } else {
      final errorData = jsonDecode(response.body);
      throw "${response.statusCode}: ${errorData['error'] ?? 'Update failed'}";
    }
  }
}
