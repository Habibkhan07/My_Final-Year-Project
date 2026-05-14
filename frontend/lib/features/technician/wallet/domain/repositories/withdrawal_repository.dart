import '../entities/payout_accounts.dart';
import '../entities/withdrawal_history_page.dart';
import '../entities/withdrawal_request.dart';

/// Repository contract for the withdrawal flow.
///
/// Backed by three tech-facing endpoints (see
/// ``backend/wallet/api/WALLET_API.md`` for the wire contracts):
///
/// * ``GET  /api/technicians/wallet/payout-accounts/``  — active payout targets (masked)
/// * ``POST /api/technicians/wallet/withdrawals/``      — submit a request
/// * ``GET  /api/technicians/wallet/withdrawals/``      — cursor-paginated history
///
/// Throws subclasses of [WithdrawalFailure] for every method — see
/// ``withdrawal_repository_impl.dart`` for the HTTP-to-domain code
/// map. The four-step error pipeline lives there: data-source throws
/// ``HttpFailure``; this repository's ``_mapFailures`` switch maps each
/// backend ``code`` to its sealed-class case.
///
/// Kept distinct from [WalletRepository] so the withdrawal feature's
/// error space (insufficient funds, duplicate pending, payout-account
/// resolution, inactive tech) doesn't leak into balance reads.
abstract class WithdrawalRepository {
  /// Fetch the tech's currently-usable bank + JazzCash payout targets.
  ///
  /// Active-only — soft-deleted accounts excluded server-side.
  /// Returns two parallel lists; either or both may be empty (an
  /// empty result is the cue for the sheet to render the "Add a
  /// payout account" empty state).
  ///
  /// Raw account numbers / mobile numbers are NOT carried — the
  /// server ships masked strings only. The masked field is the only
  /// representation that ever reaches the client.
  ///
  /// Throws:
  /// * [WithdrawalPermissionFailure] — 401/403.
  /// * [WithdrawalNetworkFailure]    — device offline (no cache fallback).
  /// * [WithdrawalServerFailure]     — 5xx or unparseable.
  Future<PayoutAccounts> listPayoutAccounts();

  /// Submit a new withdrawal request at ``status=PENDING_REVIEW``.
  ///
  /// [amount] is in rupees, must be in ``[1.00, 5000.00]`` with at
  /// most two decimal places (server-side serializer rejects anything
  /// outside this window). The service also re-asserts the bounds as
  /// defense in depth.
  ///
  /// Exactly one of [bankAccountId] / [jazzcashAccountId] must be
  /// non-null — the other must be null. XOR is enforced at the
  /// backend serializer, service, and DB.
  ///
  /// Returns the freshly-created [WithdrawalRequest] (id, status,
  /// timestamps populated) so the caller can patch UI state without
  /// a re-fetch.
  ///
  /// Throws:
  /// * [InsufficientFundsFailure]                  — 400, amount > balance.
  /// * [WalletLockoutForWithdrawalFailure]         — 403, balance < 0.
  /// * [InactiveTechnicianForWithdrawalFailure]    — 403, tech not approved or deactivated.
  /// * [DuplicatePendingWithdrawalFailure]         — 409, in-flight request exists.
  /// * [InvalidPayoutAccountFailure]               — 400, payout id IDOR / inactive / unknown.
  /// * [WithdrawalAmountOutOfRangeFailure]         — 400, amount serializer bounds.
  /// * [WithdrawalValidationFailure]               — 400, XOR rule violated.
  /// * [WithdrawalPermissionFailure]               — 401/403 generic.
  /// * [WithdrawalNetworkFailure]                  — device offline.
  /// * [WithdrawalServerFailure]                   — 5xx or unparseable.
  Future<WithdrawalRequest> createRequest({
    required double amount,
    int? bankAccountId,
    int? jazzcashAccountId,
  });

  /// Fetch one cursor-paginated page of this tech's withdrawal-request
  /// history (all statuses), newest-first.
  ///
  /// Pass [cursor] = null for the first page; pass the previous
  /// page's ``nextCursor`` to continue. Tampered cursors throw
  /// [WithdrawalValidationFailure] (server returns 400 with
  /// ``errors.cursor``).
  ///
  /// Throws:
  /// * [WithdrawalPermissionFailure] — 401/403.
  /// * [WithdrawalValidationFailure] — 400 (bad cursor / bad page_size).
  /// * [WithdrawalNetworkFailure]    — device offline.
  /// * [WithdrawalServerFailure]     — 5xx or unparseable.
  Future<WithdrawalHistoryPage> listHistory({String? cursor});
}
