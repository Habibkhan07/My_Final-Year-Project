import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/withdrawal_request.dart';
import '../providers/dependency_injection.dart';

part 'pending_withdrawal_notifier.g.dart';

/// Surfaces the tech's open in-flight withdrawal (if any) to the
/// wallet screen's pending pill.
///
/// "In-flight" = ``PENDING_REVIEW`` OR ``APPROVED`` (admin has approved
/// but not yet clicked Done; ledger row not written). Either state
/// blocks a fresh submit server-side (409), so the pill is also the
/// UX surface that explains *why* the next Withdraw tap would fail.
///
/// Implementation: fetches just the first page of history and picks
/// the newest in-flight row. Cursor pagination keeps this O(1) on
/// the wire — we never need to walk past page 1 because in-flight
/// rows are always at the head (newest-first ordering).
///
/// Refresh signals:
///   * pull-to-refresh on the wallet screen → ``ref.invalidate``.
///   * after a successful submit → the submit notifier invalidates
///     this provider so the pill appears immediately.
///
/// keepAlive: false — disposed with the wallet screen, re-fetched on
/// re-entry.
@riverpod
Future<WithdrawalRequest?> pendingWithdrawal(Ref ref) async {
  final repo = ref.read(withdrawalRepositoryProvider);
  // First page is enough: in-flight rows (PENDING_REVIEW / APPROVED)
  // are by definition the newest. We scan up to page-size results
  // (default 20 on the server) for an in-flight one. In practice
  // there's at most 1 (the server enforces "one in-flight per tech")
  // but the loop tolerates more without crashing.
  final page = await repo.listHistory();
  for (final req in page.results) {
    if (req.status.isInFlight) return req;
  }
  return null;
}
