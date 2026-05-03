// Tests for the queue notifier's `accept` / `decline` methods —
// the wire-driven half of the feature. Drives the real notifier with
// fake use cases (so we can throw arbitrary IncomingJobFailures and
// inspect the JobActionResult that surfaces) and asserts on:
//
//   * the in-flight set transitions (added on call, cleared on completion).
//   * the queue mutations (success and conflict remove the offer; network
//     and unexpected failures preserve it for retry).
//   * the second-tap defensive guard (returns AlreadyInFlight without
//     dispatching a second HTTP call).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/failures/incoming_job_failure.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/repositories/incoming_job_repository.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/use_cases/accept_job_request_use_case.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/use_cases/decline_job_request_use_case.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/dependency_injection.dart'
    as feature_di;
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/state/job_action_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

/// Configurable fake repository — captures call counts and surfaces any
/// queued exception. Per-method completers let tests drive the resolution
/// timing precisely (needed for in-flight state assertions).
class _FakeRepository implements IIncomingJobRepository {
  int acceptCalls = 0;
  int declineCalls = 0;

  /// If non-null, `accept`/`decline` await this completer before resolving
  /// or throwing. Lets tests inspect the "in-flight" state mid-call.
  Completer<void>? acceptCompleter;
  Completer<void>? declineCompleter;

  /// If non-null, the throw used to fail `accept`/`decline` after the
  /// completer resolves. Null = success.
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
    if (declineCompleter != null) {
      await declineCompleter!.future;
    }
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

ProviderContainer _buildContainer({
  required EventLocalDataSource local,
  required _FakeRepository repo,
}) {
  final container = ProviderContainer(
    overrides: [
      eventLocalDataSourceProvider.overrideWithValue(local),
      // Override the repository so the use-case providers (which depend on
      // the repo) automatically pick up the fake.
      feature_di.incomingJobRepositoryProvider.overrideWithValue(repo),
      feature_di.acceptJobRequestUseCaseProvider
          .overrideWithValue(AcceptJobRequestUseCase(repo)),
      feature_di.declineJobRequestUseCaseProvider
          .overrideWithValue(DeclineJobRequestUseCase(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Seeds a single offer at `jobId` and returns the container + repo
/// for further assertions.
({ProviderContainer container, _FakeRepository repo}) _seed({
  required int jobId,
  _FakeRepository? repository,
}) {
  final local = _MockLocal();
  when(() => local.getLastSyncTimestamp()).thenReturn(null);
  final repo = repository ?? _FakeRepository();
  final container = _buildContainer(local: local, repo: repo);
  // Wake the notifier (mirrors what AppLifecycleOrchestrator does).
  container.read(incomingJobQueueProvider);
  container
      .read(systemEventProvider.notifier)
      .processEvent(_liveEvent(id: 'e1', jobId: jobId));
  expect(container.read(incomingJobQueueProvider).queue.length, 1,
      reason: 'precondition: offer was seeded');
  return (container: container, repo: repo);
}

void main() {
  group('IncomingJobQueueNotifier.accept', () {
    test('success removes the offer and returns JobActionSuccess', () async {
      final h = _seed(jobId: 1);
      final result =
          await h.container.read(incomingJobQueueProvider.notifier).accept(1);

      expect(result, isA<JobActionSuccess>());
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      expect(h.container.read(incomingJobQueueProvider).inFlightJobIds, isEmpty);
      expect(h.repo.acceptCalls, 1);
    });

    test(
      'while in flight, the offer is in inFlightJobIds; once resolved, it '
      'is cleared (and the offer is removed)',
      () async {
        final repo = _FakeRepository()..acceptCompleter = Completer<void>();
        final h = _seed(jobId: 1, repository: repo);

        // Kick off the call but do NOT await it yet.
        final future =
            h.container.read(incomingJobQueueProvider.notifier).accept(1);

        // The notifier should have synchronously added jobId=1 to the
        // in-flight set before awaiting the use case.
        expect(
          h.container.read(incomingJobQueueProvider).inFlightJobIds,
          contains(1),
        );

        // Resolve the use case → notifier completes.
        repo.acceptCompleter!.complete();
        final result = await future;
        expect(result, isA<JobActionSuccess>());
        expect(
            h.container.read(incomingJobQueueProvider).inFlightJobIds, isEmpty);
      },
    );

    test(
      'OfferNoLongerAvailable removes the offer and returns JobActionConflict '
      'carrying the failure',
      () async {
        final repo = _FakeRepository()
          ..acceptThrow = const OfferNoLongerAvailable(currentStatus: 'REJECTED');
        final h = _seed(jobId: 1, repository: repo);

        final result =
            await h.container.read(incomingJobQueueProvider.notifier).accept(1);

        expect(result, isA<JobActionConflict>());
        final conflict = result as JobActionConflict;
        expect(conflict.failure.currentStatus, 'REJECTED');
        expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
        expect(
            h.container.read(incomingJobQueueProvider).inFlightJobIds, isEmpty);
      },
    );

    test(
      'IncomingJobNetworkFailure preserves the offer (retryable) and '
      'returns JobActionNetworkFailure',
      () async {
        final repo = _FakeRepository()
          ..acceptThrow = const IncomingJobNetworkFailure();
        final h = _seed(jobId: 1, repository: repo);

        final result =
            await h.container.read(incomingJobQueueProvider.notifier).accept(1);

        expect(result, isA<JobActionNetworkFailure>());
        // Offer must remain in the queue so the user can Retry.
        final queue = h.container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 1);
        expect(queue.single.jobId, 1);
        // In-flight cleared so the buttons re-enable.
        expect(
            h.container.read(incomingJobQueueProvider).inFlightJobIds, isEmpty);
      },
    );

    test(
      'IncomingJobServerFailure preserves the offer and returns '
      'JobActionUnexpectedFailure',
      () async {
        final repo = _FakeRepository()
          ..acceptThrow = const IncomingJobServerFailure();
        final h = _seed(jobId: 1, repository: repo);

        final result =
            await h.container.read(incomingJobQueueProvider.notifier).accept(1);

        expect(result, isA<JobActionUnexpectedFailure>());
        expect(h.container.read(incomingJobQueueProvider).queue.length, 1);
      },
    );

    test(
      'a second concurrent call for the same jobId returns AlreadyInFlight '
      'and does NOT dispatch a second HTTP call',
      () async {
        final repo = _FakeRepository()..acceptCompleter = Completer<void>();
        final h = _seed(jobId: 1, repository: repo);

        // First call — leave it pending.
        final first =
            h.container.read(incomingJobQueueProvider.notifier).accept(1);
        // Second call lands while the first is still in flight.
        final second =
            await h.container.read(incomingJobQueueProvider.notifier).accept(1);

        expect(second, isA<JobActionAlreadyInFlight>());
        expect(repo.acceptCalls, 1, reason: 'no second wire dispatch');

        // Cleanup — finish the first call.
        repo.acceptCompleter!.complete();
        await first;
      },
    );

    test(
      'accepting different jobIds in parallel works — each gets its own '
      'in-flight slot and resolves independently',
      () async {
        final repo = _FakeRepository();
        final local = _MockLocal();
        when(() => local.getLastSyncTimestamp()).thenReturn(null);
        final container = _buildContainer(local: local, repo: repo);
        container.read(incomingJobQueueProvider);
        // Seed two offers (jobId=1 head, jobId=2 tail).
        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1));
        container.read(systemEventProvider.notifier).processEvent(
              _liveEvent(
                id: 'e2',
                jobId: 2,
                agedBy: const Duration(milliseconds: 1),
              ),
            );

        final r1 = await container
            .read(incomingJobQueueProvider.notifier)
            .accept(1);
        final r2 = await container
            .read(incomingJobQueueProvider.notifier)
            .accept(2);

        expect(r1, isA<JobActionSuccess>());
        expect(r2, isA<JobActionSuccess>());
        expect(container.read(incomingJobQueueProvider).queue, isEmpty);
        expect(repo.acceptCalls, 2);
      },
    );

    test(
      'an untyped exception bubbles into JobActionUnexpectedFailure '
      '(catch-all defends against an interceptor throwing a non-mapped type)',
      () async {
        final repo = _FakeRepository()..acceptThrow = StateError('boom');
        final h = _seed(jobId: 1, repository: repo);

        final result =
            await h.container.read(incomingJobQueueProvider.notifier).accept(1);

        expect(result, isA<JobActionUnexpectedFailure>());
      },
    );
  });

  group('IncomingJobQueueNotifier.decline', () {
    test('success removes the offer and returns JobActionSuccess', () async {
      final h = _seed(jobId: 1);
      final result =
          await h.container.read(incomingJobQueueProvider.notifier).decline(1);

      expect(result, isA<JobActionSuccess>());
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
      expect(h.repo.declineCalls, 1);
    });

    test('OfferNoLongerAvailable on decline returns JobActionConflict',
        () async {
      final repo = _FakeRepository()
        ..declineThrow = const OfferNoLongerAvailable(currentStatus: 'CONFIRMED');
      final h = _seed(jobId: 1, repository: repo);

      final result =
          await h.container.read(incomingJobQueueProvider.notifier).decline(1);

      expect(result, isA<JobActionConflict>());
      expect((result as JobActionConflict).failure.currentStatus, 'CONFIRMED');
      expect(h.container.read(incomingJobQueueProvider).queue, isEmpty);
    });

    test('network failure on decline preserves the offer', () async {
      final repo = _FakeRepository()
        ..declineThrow = const IncomingJobNetworkFailure();
      final h = _seed(jobId: 1, repository: repo);

      final result =
          await h.container.read(incomingJobQueueProvider.notifier).decline(1);

      expect(result, isA<JobActionNetworkFailure>());
      expect(h.container.read(incomingJobQueueProvider).queue.length, 1);
    });

    test(
      'concurrent accept + decline on the same jobId — second call returns '
      'AlreadyInFlight regardless of which action is in flight',
      () async {
        final repo = _FakeRepository()..acceptCompleter = Completer<void>();
        final h = _seed(jobId: 1, repository: repo);

        // Accept is in flight.
        final acceptFuture =
            h.container.read(incomingJobQueueProvider.notifier).accept(1);
        // Decline lands during the in-flight window.
        final declineResult =
            await h.container.read(incomingJobQueueProvider.notifier).decline(1);

        expect(declineResult, isA<JobActionAlreadyInFlight>());
        expect(repo.declineCalls, 0, reason: 'decline must not have dispatched');

        repo.acceptCompleter!.complete();
        await acceptFuture;
      },
    );
  });
}
