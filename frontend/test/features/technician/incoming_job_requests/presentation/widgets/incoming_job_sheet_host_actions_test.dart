// Widget tests for the host's accept/decline wiring (the new behaviour
// added by flag #14):
//   * tapping Accept in the sheet calls the repository and removes the
//     offer on success.
//   * tapping Accept on a 409 surfaces "no longer available" snackbar.
//   * tapping Accept on a network failure surfaces a Retry-able snackbar
//     and the offer stays in the queue.
//   * the local SLA expiry callback is suppressed while a request is in
//     flight (the offer is not removed under the user mid-call).
//
// Drives the real notifier via overridden use-case providers — same
// pattern as `incoming_job_queue_notifier_actions_test.dart`. The host's
// 260ms accept-confirm hold is exercised end-to-end.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'package:frontend/features/technician/incoming_job_requests/domain/failures/incoming_job_failure.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/repositories/incoming_job_repository.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/use_cases/accept_job_request_use_case.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/use_cases/decline_job_request_use_case.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/dependency_injection.dart'
    as feature_di;
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/services/incoming_job_sound_player.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

class _NoopSoundPlayer implements IncomingJobSoundPlayer {
  @override
  Future<void> playNewOfferSound() async {}
}

/// Same fake the notifier-actions test uses — captures call counts and
/// surfaces a queued exception. Per-method completer lets the test drive
/// the in-flight resolution timing.
class _FakeRepository implements IIncomingJobRepository {
  int acceptCalls = 0;
  int declineCalls = 0;
  Completer<void>? acceptCompleter;
  Object? acceptThrow;
  Object? declineThrow;

  @override
  Future<void> acceptJobRequest(int jobId) async {
    acceptCalls++;
    if (acceptCompleter != null) {
      await acceptCompleter!.future;
    }
    if (acceptThrow != null) throw acceptThrow!;
  }

  @override
  Future<void> declineJobRequest(int jobId) async {
    declineCalls++;
    if (declineThrow != null) throw declineThrow!;
  }
}

SystemEventEntity _liveEvent({
  required String id,
  required int jobId,
  int expiresInSeconds = 300,
  Duration agedBy = Duration.zero,
}) {
  final now = DateTime.now().toUtc();
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'job_new_request',
    targetRoleStr: 'technician',
    timestamp: now.subtract(agedBy),
    payload: <String, dynamic>{
      'job_id': jobId,
      'service_name': 'AC Deep Wash',
      'booking_type': 'FIXED_GIG',
      'scheduled_start_iso': '2026-04-08T05:00:00Z',
      'payout': '1500',
      'payout_context': 'Fixed-price gig',
      'expires_in_seconds': expiresInSeconds,
    },
  );
}

typedef _Harness = ({ProviderContainer container, _FakeRepository repo});

Future<_Harness> _pumpHost(
  WidgetTester tester, {
  _FakeRepository? repository,
}) async {
  final repo = repository ?? _FakeRepository();
  final local = _MockLocal();
  when(() => local.getLastSyncTimestamp()).thenReturn(null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        realtime_di.eventLocalDataSourceProvider.overrideWithValue(local),
        feature_di.incomingJobSoundPlayerProvider.overrideWithValue(
          _NoopSoundPlayer(),
        ),
        feature_di.incomingJobRepositoryProvider.overrideWithValue(repo),
        feature_di.acceptJobRequestUseCaseProvider.overrideWithValue(
          AcceptJobRequestUseCase(repo),
        ),
        feature_di.declineJobRequestUseCaseProvider.overrideWithValue(
          DeclineJobRequestUseCase(repo),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: IncomingJobSheetHost(child: Center(child: Text('background'))),
        ),
      ),
    ),
  );

  final container = ProviderScope.containerOf(
    tester.element(find.byType(IncomingJobSheetHost)),
  );
  container.read(incomingJobQueueProvider);

  return (container: container, repo: repo);
}

/// Pumps long enough for the slide-up to settle so the sheet is visible
/// and tappable.
Future<void> _pumpSlideIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

/// Total wait for one accept tap: 260ms (confirm hold) + a small slack so
/// the post-await mounted check + setState lands.
const Duration _acceptTotalDelay = Duration(milliseconds: 320);

/// Invokes the sheet's `onAccept` callback directly, bypassing the swipe
/// widget — the swipe widget has its own tests; this one is about the
/// host's reaction to the callback, which is independent of how it fires.
void _invokeAccept(WidgetTester tester) {
  final sheet = tester.widget<IncomingJobSheet>(find.byType(IncomingJobSheet));
  sheet.onAccept();
}

void _invokeDecline(WidgetTester tester) {
  final sheet = tester.widget<IncomingJobSheet>(find.byType(IncomingJobSheet));
  sheet.onDecline();
}

void _invokeExpire(WidgetTester tester) {
  final sheet = tester.widget<IncomingJobSheet>(find.byType(IncomingJobSheet));
  sheet.onExpire();
}

void main() {
  group('IncomingJobSheetHost — accept wiring', () {
    testWidgets('accept calls the use case once and removes the offer', (
      tester,
    ) async {
      final h = await _pumpHost(tester);
      h.container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1));
      await _pumpSlideIn(tester);

      _invokeAccept(tester);
      // Wait through the confirm hold + the accept completion.
      await tester.pump(_acceptTotalDelay);
      await tester.pump();

      expect(h.repo.acceptCalls, 1);
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      // No snackbar on success.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'accept on 409 surfaces "no longer available" snackbar with no Retry '
      'and removes the offer',
      (tester) async {
        final repo = _FakeRepository()
          ..acceptThrow = const OfferNoLongerAvailable(
            currentStatus: 'REJECTED',
          );
        final h = await _pumpHost(tester, repository: repo);
        h.container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        await _pumpSlideIn(tester);

        _invokeAccept(tester);
        await tester.pump(_acceptTotalDelay);
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('This job is no longer available.'), findsOneWidget);
        // Conflict is non-retryable.
        expect(find.widgetWithText(SnackBarAction, 'Retry'), findsNothing);
        expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      },
    );

    testWidgets(
      'accept on network failure surfaces a Retry snackbar and the offer '
      'stays in the queue',
      (tester) async {
        final repo = _FakeRepository()
          ..acceptThrow = const IncomingJobNetworkFailure();
        final h = await _pumpHost(tester, repository: repo);
        h.container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        await _pumpSlideIn(tester);

        _invokeAccept(tester);
        await tester.pump(_acceptTotalDelay);
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.widgetWithText(SnackBarAction, 'Retry'), findsOneWidget);
        // Offer must remain so the user can Retry.
        expect(h.container.read(incomingJobQueueProvider).queue.length, 1);
      },
    );

    testWidgets(
      'accept on wallet_lockout surfaces a "Top up" snackbar carrying the '
      'owed amount, and the offer stays in the queue',
      (tester) async {
        // Backend B4 raises WalletLockoutError → maps to
        // JobAcceptBlockedByLockout → host renders snackbar with a
        // "Top up" action (not Retry — retrying without topping up first
        // would land on the same 403). Offer must stay in the queue so
        // the tech can clear lockout and re-attempt within the SLA window.
        final repo = _FakeRepository()
          ..acceptThrow = const JobAcceptBlockedByLockout(
            owedPkr: 495,
            balancePkr: -495,
          );
        final h = await _pumpHost(tester, repository: repo);
        h.container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        await _pumpSlideIn(tester);

        _invokeAccept(tester);
        await tester.pump(_acceptTotalDelay);
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(
            'Wallet locked. Top up Rs. 495 to clear the lockout.',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SnackBarAction, 'Top up'),
          findsOneWidget,
        );
        // Not a Retry — distinct CTA so the tech doesn't tap and bounce
        // off the same 403 again.
        expect(
          find.widgetWithText(SnackBarAction, 'Retry'),
          findsNothing,
        );
        // Offer stays — the lockout is potentially recoverable in-window.
        expect(h.container.read(incomingJobQueueProvider).queue.length, 1);
      },
    );

    testWidgets('tapping Retry re-invokes accept (second wire dispatch)', (
      tester,
    ) async {
      // First call fails with network; switch to success for the retry
      // by clearing acceptThrow before tapping Retry.
      final repo = _FakeRepository()
        ..acceptThrow = const IncomingJobNetworkFailure();
      final h = await _pumpHost(tester, repository: repo);
      h.container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1));
      await _pumpSlideIn(tester);

      _invokeAccept(tester);
      await tester.pump(_acceptTotalDelay);
      await tester.pump();
      expect(h.repo.acceptCalls, 1);

      // Switch the repo to success for the retry path.
      h.repo.acceptThrow = null;

      // Invoke the SnackBarAction's onPressed directly — the snackbar's
      // hit target sits below the 600px test viewport in this layout, but
      // the production user (taller phone screens, real BottomSheet
      // positioning) reaches it normally. Bypassing the gesture path
      // keeps this test focused on the wiring contract.
      final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      action.onPressed.call();

      // Retry re-invokes _handleAccept which awaits the 260ms hold.
      await tester.pump(_acceptTotalDelay);
      await tester.pump();

      expect(h.repo.acceptCalls, 2);
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
    });

    testWidgets(
      'a second tap during the in-flight window does NOT dispatch a second '
      'wire call',
      (tester) async {
        final repo = _FakeRepository()..acceptCompleter = Completer<void>();
        final h = await _pumpHost(tester, repository: repo);
        h.container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        await _pumpSlideIn(tester);

        _invokeAccept(tester);
        // Pump past the 260ms confirm hold so the call has been issued.
        await tester.pump(const Duration(milliseconds: 280));

        // Second tap lands while the first is still pending — must be a no-op.
        _invokeAccept(tester);
        await tester.pump(const Duration(milliseconds: 280));

        expect(h.repo.acceptCalls, 1);
        // Cleanup.
        repo.acceptCompleter!.complete();
        await tester.pump();
      },
    );

    testWidgets(
      '_handleExpire is suppressed while the offer is in flight — the '
      'card does not pop out under the user mid-request',
      (tester) async {
        final repo = _FakeRepository()..acceptCompleter = Completer<void>();
        final h = await _pumpHost(tester, repository: repo);
        h.container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        await _pumpSlideIn(tester);

        _invokeAccept(tester);
        // Past the 260ms confirm hold — request is in flight, in-flight
        // set contains jobId=1.
        await tester.pump(const Duration(milliseconds: 280));
        expect(
          h.container.read(incomingJobQueueProvider).inFlightJobIds,
          contains(1),
        );

        // Expire fires (the swipe widget's drain reached zero).
        _invokeExpire(tester);
        await tester.pump();

        // Offer must still be in the queue — the in-flight gate suppressed
        // the expiry-triggered local removal.
        expect(h.container.read(incomingJobQueueProvider).queue.length, 1);

        // Now resolve the request → offer is removed via the success path.
        repo.acceptCompleter!.complete();
        await tester.pump();
        await tester.pump();
        expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      },
    );
  });

  group('IncomingJobSheetHost — decline wiring', () {
    testWidgets('decline calls the use case once and removes the offer', (
      tester,
    ) async {
      final h = await _pumpHost(tester);
      h.container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1));
      await _pumpSlideIn(tester);

      _invokeDecline(tester);
      // Decline has no confirm-hold; await microtask + completion.
      await tester.pump();
      await tester.pump();

      expect(h.repo.declineCalls, 1);
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('decline on 409 surfaces the "no longer available" snackbar', (
      tester,
    ) async {
      final repo = _FakeRepository()
        ..declineThrow = const OfferNoLongerAvailable(
          currentStatus: 'CONFIRMED',
        );
      final h = await _pumpHost(tester, repository: repo);
      h.container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1));
      await _pumpSlideIn(tester);

      _invokeDecline(tester);
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('This job is no longer available.'), findsOneWidget);
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
    });
  });
}
