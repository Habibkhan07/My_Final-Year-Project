import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/payout_account_model.dart';
import '../models/withdrawal_request_model.dart';

/// HTTP data-source for the withdrawal flow.
///
/// Three endpoints, one auth strategy (Token header from
/// [AuthLocalDataSource]). Every non-2xx response is converted to an
/// [HttpFailure] by [_handleResponse]; the repository's
/// ``_mapFailures`` switch is the next step in the 4-step error
/// pipeline.
abstract class IWithdrawalRemoteDataSource {
  /// GET ``/wallet/payout-accounts/`` — active bank + JazzCash targets.
  Future<PayoutAccountsModel> listPayoutAccounts();

  /// POST ``/wallet/withdrawals/`` — submit a new withdrawal.
  ///
  /// Exactly one of [bankAccountId] / [jazzcashAccountId] must be
  /// non-null. The repository's validation is the first line of
  /// defense; the server XOR rule is the second.
  ///
  /// [amount] is in rupees with 2dp precision. Stringified for the
  /// wire so the server receives a Decimal — sending a raw double
  /// would risk float-rounding drift on edge values.
  Future<WithdrawalRequestModel> createRequest({
    required double amount,
    int? bankAccountId,
    int? jazzcashAccountId,
  });

  /// GET ``/wallet/withdrawals/?cursor=...`` — cursor-paginated history
  /// of this tech's own requests.
  Future<WithdrawalHistoryPageModel> listHistory({String? cursor});
}

class WithdrawalRemoteDataSource implements IWithdrawalRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  final String baseUrl = '${AppConstants.baseUrl}/technicians';

  WithdrawalRemoteDataSource({
    required this.client,
    required this.authLocalDataSource,
  });

  Future<Map<String, String>> _headers() async {
    final token = await authLocalDataSource.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  @override
  Future<PayoutAccountsModel> listPayoutAccounts() async {
    final uri = Uri.parse('$baseUrl/wallet/payout-accounts/');
    final response = await client.get(uri, headers: await _headers());
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PayoutAccountsModel.fromJson(data);
  }

  @override
  Future<WithdrawalRequestModel> createRequest({
    required double amount,
    int? bankAccountId,
    int? jazzcashAccountId,
  }) async {
    final uri = Uri.parse('$baseUrl/wallet/withdrawals/');
    // Send the amount as a 2dp string. The server's DecimalField is
    // strict about precision (extra dp → 400); using ``toStringAsFixed``
    // pins us to the contract regardless of the caller's input.
    final body = <String, dynamic>{
      'amount': amount.toStringAsFixed(2),
      'payout_bank_account_id': ?bankAccountId,
      'payout_jazzcash_account_id': ?jazzcashAccountId,
    };
    final response = await client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WithdrawalRequestModel.fromJson(data);
  }

  @override
  Future<WithdrawalHistoryPageModel> listHistory({String? cursor}) async {
    final uri = Uri.parse('$baseUrl/wallet/withdrawals/').replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final response = await client.get(uri, headers: await _headers());
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WithdrawalHistoryPageModel.fromJson(data);
  }

  /// Convert any non-2xx response into an [HttpFailure] carrying the
  /// canonical envelope's ``code`` / ``message`` / ``errors``. Mirrors
  /// the wallet data-source's helper so the two share a parse strategy.
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    Object? body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }
    throw HttpFailure.fromEnvelope(
      statusCode: response.statusCode,
      body: body,
      fallbackCode: 'server_error',
      fallbackMessage: 'Server error: ${response.statusCode}',
    );
  }
}
