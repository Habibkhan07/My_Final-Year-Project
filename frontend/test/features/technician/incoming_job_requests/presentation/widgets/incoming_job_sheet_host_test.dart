// Widget tests for [IncomingJobSheetHost]. Pins the four cases of the
// `_onQueueChanged` listener and the head-change vanish-reappear ceremony,
// using the real queue notifier (so the test exercises the boot-hooks
// wake-up path and the head-sticky priority queue end-to-end) plus a
// capturing fake of [IncomingJobSoundPlayer] (so the audio cue is
// observable without firing real platform sounds).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/services/incoming_job_sound_player.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

/// Captures every call to `playNewOfferSound`. Used as an override of
/// `incomingJobSoundPlayerProvider` so the host's ceremony fires through a
/// counter we can assert on.
class _CapturingSoundPlayer implements IncomingJobSoundPlayer {
  int callCount = 0;

  @override
  Future<void> playNewOfferSound() async {
    callCount++;
  }
}

/// Builds a `job_new_request` system event whose timestamp is `now -
/// agedBy` (default: now). Pass distinct `agedBy` values across events in a
/// test so the SystemEventNotifier's monotonic same-type order guard
/// accepts each one.
SystemEventEntity _liveEvent({
  required String id,
  required int jobId,
  required String serviceName,
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
      'service_name': serviceName,
      'booking_type': 'FIXED_GIG',
      'scheduled_start_iso': '2026-04-08T05:00:00Z',
      'payout': '1500',
      'payout_context': 'Fixed-price gig',
      'expires_in_seconds': expiresInSeconds,
    },
  );
}

/// Mounts the host inside a ProviderScope with the standard test overrides
/// and returns the harness for triggering events / asserting on the
/// capturing sound player.
typedef _HostHarness = ({
  _CapturingSoundPlayer sound,
  ProviderContainer container,
});

Future<_HostHarness> _pumpHost(WidgetTester tester) async {
  final sound = _CapturingSoundPlayer();
  final local = _MockLocal();
  when(() => local.getLastSyncTimestamp()).thenReturn(null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        realtime_di.eventLocalDataSourceProvider.overrideWithValue(local),
        incomingJobSoundPlayerProvider.overrideWithValue(sound),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: IncomingJobSheetHost(
            child: Center(child: Text('background')),
          ),
        ),
      ),
    ),
  );

  final container = ProviderScope.containerOf(
    tester.element(find.byType(IncomingJobSheetHost)),
  );
  // Wake the queue notifier (mirrors `bootAfterAuth`). Without this the
  // notifier never subscribes to systemEventProvider and the first event
  // is silently dropped.
  container.read(incomingJobQueueProvider);

  return (sound: sound, container: container);
}

/// Pumps long enough for the host's ~280ms slide-up animation to settle.
Future<void> _pumpSlideIn(WidgetTester tester) async {
  await tester.pump(); // listener fires, _showController.forward starts
  await tester.pump(const Duration(milliseconds: 320));
}

/// Pumps long enough for the host's ~220ms slide-down animation to settle.
Future<void> _pumpSlideOut(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

void main() {
  group('IncomingJobSheetHost — `_onQueueChanged` four cases', () {
    testWidgets(
      'case 1: empty → first arrival mounts the sheet and slides in',
      (tester) async {
        final harness = await _pumpHost(tester);

        expect(find.byType(IncomingJobSheet), findsNothing,
            reason: 'no offers yet → no sheet');

        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(id: 'e1', jobId: 1, serviceName: 'Plumbing Inspection'),
            );

        await _pumpSlideIn(tester);

        expect(find.byType(IncomingJobSheet), findsOneWidget);
        expect(find.text('Plumbing Inspection'), findsOneWidget);
        expect(harness.sound.callCount, 0,
            reason: 'first arrival is not a head-change ceremony');
      },
    );

    testWidgets(
      'case 2: non-empty → empty slides the sheet out and unmounts',
      (tester) async {
        final harness = await _pumpHost(tester);

        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(id: 'e1', jobId: 1, serviceName: 'AC Repair'),
            );
        await _pumpSlideIn(tester);
        expect(find.byType(IncomingJobSheet), findsOneWidget);

        // Resolve the only offer in the queue (decline / expire would have
        // the same effect).
        harness.container
            .read(incomingJobQueueProvider.notifier)
            .removeRequest(1);
        await _pumpSlideOut(tester);

        expect(find.byType(IncomingJobSheet), findsNothing);
        expect(harness.sound.callCount, 0,
            reason: 'queue emptied — no new offer to announce');
      },
    );

    testWidgets(
      'case 3: head change runs the vanish-reappear ceremony — sheet '
      'slide-out, pause, sound, slide-in with new content',
      (tester) async {
        final harness = await _pumpHost(tester);

        // Seed two offers — A first (head), B second (tail). agedBy ensures
        // distinct monotonic timestamps so SystemEventNotifier's order guard
        // accepts both.
        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(
                id: 'e1',
                jobId: 1,
                serviceName: 'Job Alpha',
                agedBy: const Duration(seconds: 2),
              ),
            );
        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(id: 'e2', jobId: 2, serviceName: 'Job Bravo'),
            );

        await _pumpSlideIn(tester);

        // Job Alpha is the head and is visible. Sound has not fired (case
        // 4 — tail-only growth — does not fire it).
        expect(find.text('Job Alpha'), findsOneWidget);
        expect(find.text('Job Bravo'), findsNothing);
        expect(harness.sound.callCount, 0);

        // Resolve the head — triggers the head-change ceremony.
        harness.container
            .read(incomingJobQueueProvider.notifier)
            .removeRequest(1);

        // After ~220ms the slide-out completes. We're now in the 250ms
        // pause; the sound has not fired yet.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 230));
        expect(harness.sound.callCount, 0,
            reason: 'sound fires AFTER the pause, not during slide-out');

        // After the pause completes the sound fires once.
        await tester.pump(const Duration(milliseconds: 260));
        expect(harness.sound.callCount, 1,
            reason: 'ceremony plays exactly one new-offer sound');

        // After the slide-in completes Job Bravo is visible; Job Alpha is
        // gone from the tree.
        await tester.pump(const Duration(milliseconds: 320));
        expect(find.text('Job Bravo'), findsOneWidget);
        expect(find.text('Job Alpha'), findsNothing);
      },
    );

    testWidgets(
      'case 4: tail-only growth keeps the head visible and does NOT fire '
      'the sound',
      (tester) async {
        final harness = await _pumpHost(tester);

        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(
                id: 'e1',
                jobId: 1,
                serviceName: 'Job Alpha',
                agedBy: const Duration(seconds: 2),
              ),
            );
        await _pumpSlideIn(tester);
        expect(find.text('Job Alpha'), findsOneWidget);
        expect(harness.sound.callCount, 0);

        // Tail growth — head stays Alpha.
        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(id: 'e2', jobId: 2, serviceName: 'Job Bravo'),
            );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Job Alpha'), findsOneWidget,
            reason: 'head-sticky — visible card does not swap');
        expect(find.text('Job Bravo'), findsNothing,
            reason: 'tail entry must not appear in the rendered card');
        expect(harness.sound.callCount, 0,
            reason: 'no head-change → no ceremony → no sound');
      },
    );
  });

  group('IncomingJobSheetHost — `_handleAccept` 260ms confirm hold', () {
    testWidgets(
      'firing the sheet\'s onAccept callback holds removeRequest until '
      '~260ms have passed (so the swipe widget can play its confirm '
      'animation visibly before the head leaves the queue)',
      (tester) async {
        // Test goal: verify `_handleAccept`'s hold contract. We invoke the
        // host's onAccept callback directly via the rendered IncomingJobSheet
        // instead of dragging the swipe widget — the gesture path is already
        // pinned by `incoming_job_swipe_to_accept_test.dart`, and going
        // through DraggableScrollableSheet's gesture arena adds noise that
        // doesn't change what this test is here to verify.
        final harness = await _pumpHost(tester);

        harness.container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(id: 'e1', jobId: 1, serviceName: 'Job Alpha'),
            );
        await _pumpSlideIn(tester);

        final sheet = tester.widget<IncomingJobSheet>(
          find.byType(IncomingJobSheet),
        );
        sheet.onAccept();

        // 100ms in: the host has accepted but is holding `removeRequest`
        // while the swipe widget plays its confirm animation. Queue still
        // has the offer.
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          harness.container.read(incomingJobQueueProvider).queue.length,
          1,
          reason: 'removeRequest must wait until the confirm animation has '
              'played; the head should still be in the queue mid-hold',
        );

        // After the 260ms hold completes the deferred removeRequest fires
        // and the queue empties (case 2 — slide-out begins, no tail to
        // promote).
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          harness.container.read(incomingJobQueueProvider).queue,
          isEmpty,
          reason: 'after the hold, removeRequest should have fired',
        );
      },
    );
  });
}
