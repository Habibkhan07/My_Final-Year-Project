import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/topup_status_type.dart';
import '../../domain/failures/topup_failure.dart';
import '../providers/dependency_injection.dart';
import 'topup_state.dart';

part 'topup_notifier.g.dart';

/// Drives the JazzCash Hosted Checkout top-up state machine.
///
/// Single source of truth for a multi-screen flow:
///
///   1. ``TopupAmountSheet`` reads ``state.flow == idle`` and calls
///      [start] on submit.
///   2. ``WalletScreen`` watches the state; when it transitions to
///      ``awaitingGateway`` it pushes the ``JazzCashWebviewScreen``
///      with ``state.session!.redirectUrl``.
///   3. The webview's ``NavigationDelegate`` calls [onGatewayReturned]
///      when JazzCash POSTs the browser back to our ``pp_ReturnURL``;
///      this transitions to ``verifying`` and kicks off the poll.
///   4. The poll resolves the terminal status. State flips to
///      ``success`` or ``failed`` accordingly.
///   5. ``WalletScreen`` reacts to the terminal state by showing the
///      ``TopupResultSheet`` and the realtime ``wallet_balance_updated``
///      event has already patched the balance card.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) because the flow has more
/// states than just loading/data/error; the AsyncValue wrapper would
/// just get in the way. Errors are captured inside the state's
/// ``failure`` field instead.
@riverpod
class TopupNotifier extends _$TopupNotifier {
  /// Poll cadence + budget. Server-side processing is synchronous
  /// inside ``JazzCashReturnView``, so by the time the webview
  /// finishes its POST the ledger row already exists. The poll loop
  /// exists to defend against (a) webhook arrival lagging the webview
  /// pop, and (b) JazzCash retries that have momentarily put us in a
  /// pending state.
  static const Duration _pollInterval = Duration(seconds: 2);
  static const int _pollMaxAttempts = 15; // 30s budget at 2s cadence

  /// Tracks the active poll timer so [onGatewayAborted] can cancel it
  /// if the user backs out of the result while polling is ongoing.
  Timer? _pollTimer;

  @override
  TopupState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const TopupState();
  }

  /// Step 1 — kick off the top-up flow with a whole-rupee amount.
  ///
  /// Transitions: ``idle → starting → awaitingGateway`` on success,
  /// or ``starting → failed`` on any [TopupFailure].
  Future<void> start(int amountRs) async {
    if (state.flow != TopupFlow.idle && state.flow != TopupFlow.failed) {
      // Guard against double-tap on the Continue button: ignore if
      // already in flight or in a non-restartable mid-flow state.
      return;
    }

    state = TopupState(flow: TopupFlow.starting);

    try {
      final repo = ref.read(walletRepositoryProvider);
      final session = await repo.startTopup(amountRs: amountRs);
      state = TopupState(
        flow: TopupFlow.awaitingGateway,
        session: session,
      );
    } on TopupFailure catch (failure) {
      state = TopupState(flow: TopupFlow.failed, failure: failure);
    } catch (e) {
      // Belt-and-braces for anything that escaped the repository
      // mapper — wrap so the UI still sees a sealed failure.
      state = TopupState(
        flow: TopupFlow.failed,
        failure: TopupServerFailure('Unexpected error: $e'),
      );
    }
  }

  /// Step 3 — webview detected the return URL and popped itself.
  ///
  /// Transitions: ``awaitingGateway → verifying`` and kicks off the
  /// poll loop. A no-op if we're not currently in [awaitingGateway]
  /// (e.g. user aborted, or this is a stale callback).
  void onGatewayReturned() {
    if (state.flow != TopupFlow.awaitingGateway) return;
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(flow: TopupFlow.verifying);
    _pollAttempts = 0;
    _scheduleNextPoll(session.topupId);
  }

  /// User explicitly closed the webview / mock-bridge page without
  /// reaching a terminal state. Transitions directly to ``failed``
  /// with [TopupUserAborted] — distinct from a gateway-side failure
  /// so analytics + result-sheet copy can branch.
  void onGatewayAborted() {
    if (state.flow != TopupFlow.awaitingGateway &&
        state.flow != TopupFlow.verifying) {
      return;
    }
    _pollTimer?.cancel();
    state = TopupState(
      flow: TopupFlow.failed,
      failure: const TopupUserAborted(),
    );
  }

  /// Returns the state to ``idle`` so the wallet screen can dismiss
  /// the result sheet and the next "Top up" tap starts fresh.
  void reset() {
    _pollTimer?.cancel();
    state = const TopupState();
  }

  // ---------------------------------------------------------------
  // Poll machinery
  // ---------------------------------------------------------------

  int _pollAttempts = 0;

  void _scheduleNextPoll(int topupId) {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, () => _runPoll(topupId));
  }

  Future<void> _runPoll(int topupId) async {
    if (state.flow != TopupFlow.verifying) {
      // We've transitioned out (e.g. user aborted) — stop polling.
      return;
    }
    _pollAttempts++;
    try {
      final repo = ref.read(walletRepositoryProvider);
      final topup = await repo.pollTopupStatus(topupId: topupId);

      if (topup.isTerminal) {
        state = state.copyWith(
          flow:
              topup.status == TopupStatusType.completed
                  ? TopupFlow.success
                  : TopupFlow.failed,
          terminalStatus: topup,
          // No gateway-side failure to populate; copy is derived from
          // the status enum at the result-sheet boundary.
        );
        return;
      }

      if (_pollAttempts >= _pollMaxAttempts) {
        state = state.copyWith(
          flow: TopupFlow.failed,
          failure: const TopupPollTimeout(),
        );
        return;
      }

      _scheduleNextPoll(topupId);
    } on TopupFailure catch (failure) {
      state = state.copyWith(flow: TopupFlow.failed, failure: failure);
    } catch (e) {
      state = state.copyWith(
        flow: TopupFlow.failed,
        failure: TopupServerFailure('Unexpected error: $e'),
      );
    }
  }

  /// Test hook — forces a poll attempt without waiting for the timer.
  /// Wraps the same path the timer callback hits.
  @visibleForTesting
  Future<void> debugPollOnce(int topupId) => _runPoll(topupId);
}
