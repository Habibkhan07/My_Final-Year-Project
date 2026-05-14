import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/payout_accounts.dart';
import '../../domain/entities/withdrawal_history_page.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/failures/withdrawal_failure.dart';
import '../../domain/repositories/withdrawal_repository.dart';
import '../data_sources/withdrawal_remote_data_source.dart';

/// Concrete withdrawal repository — step 2 of the 4-step error pipeline.
///
/// Each method funnels through ``try { remote → toEntity } catch ...``:
///   * ``HttpFailure`` → [_mapHttpFailure] sealed-class case
///   * ``SocketException`` → [WithdrawalNetworkFailure] (no cache fallback)
///   * ``FormatException`` → [WithdrawalServerFailure]
///   * anything else → [WithdrawalServerFailure] with the raw `toString()`
///
/// **No offline cache** for any method on this repository. Withdrawals
/// are money-movement requests; a stale balance read followed by a
/// "success" return would be a financial-correctness bug. The wallet-
/// vs-financial-truth rule (see [WalletNetworkFailure]'s docstring)
/// applies double here.
class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final IWithdrawalRemoteDataSource remoteDataSource;

  WithdrawalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PayoutAccounts> listPayoutAccounts() async {
    try {
      final model = await remoteDataSource.listPayoutAccounts();
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException catch (_) {
      throw const WithdrawalNetworkFailure();
    } on FormatException catch (_) {
      throw const WithdrawalServerFailure('Could not parse payout-accounts response.');
    } on WithdrawalFailure {
      rethrow;
    } catch (e) {
      throw WithdrawalServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<WithdrawalRequest> createRequest({
    required double amount,
    int? bankAccountId,
    int? jazzcashAccountId,
  }) async {
    try {
      final model = await remoteDataSource.createRequest(
        amount: amount,
        bankAccountId: bankAccountId,
        jazzcashAccountId: jazzcashAccountId,
      );
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException catch (_) {
      throw const WithdrawalNetworkFailure();
    } on FormatException catch (_) {
      throw const WithdrawalServerFailure('Could not parse withdrawal response.');
    } on WithdrawalFailure {
      rethrow;
    } catch (e) {
      throw WithdrawalServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<WithdrawalHistoryPage> listHistory({String? cursor}) async {
    try {
      final model = await remoteDataSource.listHistory(cursor: cursor);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException catch (_) {
      throw const WithdrawalNetworkFailure();
    } on FormatException catch (_) {
      throw const WithdrawalServerFailure('Could not parse history response.');
    } on WithdrawalFailure {
      rethrow;
    } catch (e) {
      throw WithdrawalServerFailure('Unexpected error: $e');
    }
  }

  /// Map the canonical envelope's ``code`` to a sealed-class case.
  ///
  /// Order matters where two codes share a status (the wallet_lockout
  /// branch precedes the generic 401/403 catch-all). We branch on
  /// ``code`` first, then fall back to status for codes we don't
  /// recognise — a forward-compatible new server code lands in the
  /// generic-server-failure bucket instead of crashing.
  WithdrawalFailure _mapHttpFailure(HttpFailure e) {
    switch (e.code) {
      case 'insufficient_funds':
        return InsufficientFundsFailure(
          requestedPkr: _intFromEnvelope(e.errors, 'requested_pkr'),
          availablePkr: _intFromEnvelope(e.errors, 'available_pkr'),
          customMessage: e.message.isNotEmpty ? e.message : null,
        );
      case 'wallet_lockout':
        return WalletLockoutForWithdrawalFailure(
          balancePkr: _intFromEnvelope(e.errors, 'balance_pkr'),
          owedPkr: _intFromEnvelope(e.errors, 'owed_pkr'),
        );
      case 'duplicate_pending_withdrawal':
        return DuplicatePendingWithdrawalFailure(
          pendingRequestId: _intFromEnvelope(e.errors, 'pending_request_id'),
        );
      case 'inactive_technician':
        return InactiveTechnicianForWithdrawalFailure(
          status: _stringFromEnvelope(e.errors, 'status'),
        );
      case 'permission_denied':
        return WithdrawalPermissionFailure(
          e.message.isNotEmpty
              ? e.message
              : 'You do not have permission to withdraw.',
        );
      case 'validation_error':
        return _mapValidationError(e);
      case 'not_found':
        // 404 on this surface only happens on bad URL or removed
        // endpoint — treat as server failure, not as permission.
        return WithdrawalServerFailure(e.message);
      default:
        if (e.statusCode == 401 || e.statusCode == 403) {
          return const WithdrawalPermissionFailure();
        }
        if (e.statusCode >= 500) {
          return WithdrawalServerFailure(
            e.message.isNotEmpty ? e.message : 'Server error.',
          );
        }
        return WithdrawalServerFailure(
          e.message.isNotEmpty ? e.message : 'Unexpected server response.',
        );
    }
  }

  /// Narrow ``validation_error`` envelopes to the right sealed-class
  /// case based on which field(s) the server reported. Three distinct
  /// flavours collapse to the same backend code:
  ///
  ///   * ``errors.amount`` present     → [WithdrawalAmountOutOfRangeFailure]
  ///   * ``errors.payout_bank_account_id`` OR
  ///     ``errors.payout_jazzcash_account_id`` present →
  ///                                    [InvalidPayoutAccountFailure]
  ///   * ``errors.payout`` present     → [WithdrawalValidationFailure]
  ///                                    (XOR rule violation — sheet
  ///                                    surfaces server's message)
  ///   * anything else                 → [WithdrawalValidationFailure]
  ///                                    (forward-compat for unknown
  ///                                    fields)
  WithdrawalFailure _mapValidationError(HttpFailure e) {
    if (e.errors.containsKey('amount')) {
      final amountMsg = _stringFromEnvelope(e.errors, 'amount');
      return WithdrawalAmountOutOfRangeFailure(
        amountMsg.isNotEmpty ? amountMsg : 'Amount is out of range.',
      );
    }
    if (e.errors.containsKey('payout_bank_account_id') ||
        e.errors.containsKey('payout_jazzcash_account_id')) {
      return const InvalidPayoutAccountFailure();
    }
    return WithdrawalValidationFailure(
      e.message.isNotEmpty ? e.message : 'Invalid input.',
    );
  }

  /// Pull a single integer out of the canonical envelope's ``errors``
  /// map. Wire shape is ``{"field": ["value"]}`` (DRF list convention).
  /// Defensively accepts either a list-of-strings or a bare value so a
  /// future wire-shape simplification doesn't crash the parser.
  /// Returns 0 on any parse failure — the UI will show "Rs. 0" rather
  /// than throw, which is a degraded but recoverable surface.
  static int _intFromEnvelope(Map<String, dynamic> errors, String key) {
    final raw = errors[key];
    final str = raw is List && raw.isNotEmpty
        ? raw.first.toString()
        : raw?.toString();
    return int.tryParse(str ?? '') ?? 0;
  }

  /// Pull a single string out of the canonical envelope. Same coerce
  /// strategy as [_intFromEnvelope]; returns ``""`` on missing/empty.
  static String _stringFromEnvelope(Map<String, dynamic> errors, String key) {
    final raw = errors[key];
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    return raw?.toString() ?? '';
  }
}
