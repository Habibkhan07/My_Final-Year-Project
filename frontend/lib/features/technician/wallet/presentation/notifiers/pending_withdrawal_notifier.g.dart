// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_withdrawal_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(pendingWithdrawal)
final pendingWithdrawalProvider = PendingWithdrawalProvider._();

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

final class PendingWithdrawalProvider
    extends
        $FunctionalProvider<
          AsyncValue<WithdrawalRequest?>,
          WithdrawalRequest?,
          FutureOr<WithdrawalRequest?>
        >
    with
        $FutureModifier<WithdrawalRequest?>,
        $FutureProvider<WithdrawalRequest?> {
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
  PendingWithdrawalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingWithdrawalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingWithdrawalHash();

  @$internal
  @override
  $FutureProviderElement<WithdrawalRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WithdrawalRequest?> create(Ref ref) {
    return pendingWithdrawal(ref);
  }
}

String _$pendingWithdrawalHash() => r'9bb6912bebc9e7d02f2d6c3ef8214d17480bfa16';
