import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/technician_dashboard_model.dart';

/// Result of [ITechnicianDashboardRemoteDataSource.setOnline] — mirrors
/// the backend payload (`is_online` + `current_wallet_balance`). The
/// balance is parsed from the stringified Decimal the backend emits to
/// preserve precision on the wire.
typedef OnlineToggleRemoteResult = ({bool isOnline, double walletBalance});

abstract class ITechnicianDashboardRemoteDataSource {
  Future<TechnicianDashboardModel> getDashboard();

  /// POST /api/technicians/me/online/ with body `{is_online: desired}`.
  /// Returns the post-commit (`is_online`, `walletBalance`) from the
  /// 200 response. Errors propagate as [HttpFailure] (code-bearing for
  /// `wallet_lockout`, generic otherwise) — repository maps them to
  /// the sealed domain failures.
  Future<OnlineToggleRemoteResult> setOnline(bool desired);
}

class TechnicianDashboardRemoteDataSource
    implements ITechnicianDashboardRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  final String baseUrl = "${AppConstants.baseUrl}/technicians";

  TechnicianDashboardRemoteDataSource({
    required this.client,
    required this.authLocalDataSource,
  });

  @override
  Future<TechnicianDashboardModel> getDashboard() async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/dashboard/');

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);

    final data = jsonDecode(response.body);
    return TechnicianDashboardModel.fromJson(data);
  }

  @override
  Future<OnlineToggleRemoteResult> setOnline(bool desired) async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/me/online/');

    // Bound the wait — a hung backend (slow query / half-open socket)
    // would otherwise leave `toggleStatus` stuck in AsyncLoading
    // forever, disabling the toggle pill with no recovery path short
    // of force-quit. 10s is the same order of magnitude as the
    // Google Directions service (8s) and gives PG enough headroom
    // for the select_for_update + lockout check under load.
    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'is_online': desired}),
    ).timeout(const Duration(seconds: 10));

    _handleResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    // `current_wallet_balance` is a stringified Decimal — preserves
    // paisa precision over the wire. Parse to double for FE arithmetic.
    return (
      isOnline: data['is_online'] as bool,
      walletBalance: double.parse(data['current_wallet_balance'] as String),
    );
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'],
          message: body['message'] ?? 'An error occurred',
          errors: body['errors'] ?? {},
        );
      }

      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body['detail'] ?? body['error'] ?? 'Unknown error',
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
