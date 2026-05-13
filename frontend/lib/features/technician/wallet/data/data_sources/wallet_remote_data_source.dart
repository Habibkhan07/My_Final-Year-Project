import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/topup_session_model.dart';
import '../models/topup_status_model.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class IWalletRemoteDataSource {
  Future<WalletBalanceModel> getBalance();

  /// GET ``/wallet/transactions/?cursor=...`` — cursor-paginated ledger
  /// list, newest-first. ``cursor`` is the opaque token from the
  /// previous page's ``next_cursor`` field, or null for the first page.
  Future<WalletTransactionPageModel> listTransactions({String? cursor});

  /// POST ``/wallet/topups/`` — start a Hosted Checkout top-up.
  ///
  /// [amountRs] is whole rupees (Rs.100..25,000 server-side).
  Future<TopupSessionModel> startTopup({required int amountRs});

  /// GET ``/wallet/topups/<id>/`` — poll a topup's terminal status.
  Future<TopupStatusModel> getTopupStatus({required int topupId});
}

class WalletRemoteDataSource implements IWalletRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  final String baseUrl = '${AppConstants.baseUrl}/technicians';

  WalletRemoteDataSource({
    required this.client,
    required this.authLocalDataSource,
  });

  @override
  Future<WalletBalanceModel> getBalance() async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/wallet/');

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WalletBalanceModel.fromJson(data);
  }

  @override
  Future<WalletTransactionPageModel> listTransactions({String? cursor}) async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/wallet/transactions/').replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WalletTransactionPageModel.fromJson(data);
  }

  @override
  Future<TopupSessionModel> startTopup({required int amountRs}) async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/wallet/topups/');

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode({'amount': amountRs}),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TopupSessionModel.fromJson(data);
  }

  @override
  Future<TopupStatusModel> getTopupStatus({required int topupId}) async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$baseUrl/wallet/topups/$topupId/');

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TopupStatusModel.fromJson(data);
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
