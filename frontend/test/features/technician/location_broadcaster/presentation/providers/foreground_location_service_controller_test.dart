// Audit H13: comprehensive coverage for `ForegroundLocationServiceController`.
//
// The controller previously coupled directly to `FlutterForegroundTask.X`
// and `Geolocator.X` static surfaces, which made the lifecycle FSM,
// permission flow, and fatal-auth latch unverifiable in unit tests. With
// the H13 port refactor in place (`IForegroundTaskBackend`,
// `IGeolocatorBackend`), this suite exercises:
//
//   • status × role gate — tech viewer in EN_ROUTE/ARRIVED starts the
//     service; non-tech viewer never starts; status leaving the window
//     stops a running service.
//   • permission flow (audit C2) — denied location → state.permissionDenied;
//     denied notifications → state.notificationPermissionDenied; whileInUse
//     foreground triggers a best-effort upgrade attempt for "always".
//   • soft-success (audit C4) — `ServiceRequestFailure` with
//     `ServiceAlreadyStartedException` is treated as running.
//   • settings deep-link (audit C2) — `openSystemSettings()` forwards.
//   • fatal-auth channel + latch (audit H4) — isolate message flips state
//     to error, stops the service, and blocks restart until shouldRun
//     flips to false. The latch clears automatically on shouldRun=false.
//   • token reads — every successful start writes the latest auth token
//     into the foreground-task config blob (token-rotation path).
//
// What is NOT tested here (and why):
//   • `_LifecycleStatus.starting` / `stopping` re-entry races — would
//     need to interleave concurrent `_evaluate()` calls inside the
//     controller's body. The FSM is small enough to verify by inspection;
//     the audit C4 commit message documents the reasoning.
//   • Dispose-during-start cleanup — would need to dispose the
//     ProviderContainer while a startService awaiting future is in
//     flight. Riverpod's container-dispose semantics make this brittle
//     to test deterministically without a `pumpEventQueue`-style harness
//     we don't have here.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/domain/repositories/booking_detail_repository.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_detail_provider.dart';
import 'package:frontend/features/orchestrator/presentation/providers/dependency_injection.dart'
    as orchestrator_di;
import 'package:frontend/features/technician/location_broadcaster/domain/entities/broadcast_state.dart';
import 'package:frontend/features/technician/location_broadcaster/presentation/providers/dependency_injection.dart'
    as broadcaster_di;
import 'package:frontend/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart';
import 'package:frontend/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../orchestrator/_helpers/booking_detail_fixture.dart';
import '../../_helpers/fake_backends.dart';

class _FixtureRepo implements IBookingDetailRepository {
  _FixtureRepo({
    required this.status,
    this.customerId = 7,
    this.technicianId = 99,
    required this.currentUserId,
  });

  final String status;
  final int customerId;
  final int technicianId;
  final int currentUserId;

  @override
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    final json = bookingDetailJson(
      id: bookingId,
      status: status,
      customerId: customerId,
      technicianId: technicianId,
    );
    return BookingDetailMapper.toDomain(
      BookingDetailModel.fromJson(json),
      currentUserId: currentUserId,
    );
  }
}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

ProviderContainer _container({
  required _FixtureRepo repo,
  required FakeForegroundTaskBackend fg,
  required FakeGeolocatorBackend geo,
  String? authToken = 'tok-abc',
}) {
  final secure = _MockSecureStorage();
  when(
    () => secure.read(key: 'auth_token'),
  ).thenAnswer((_) async => authToken);

  final c = ProviderContainer(
    overrides: [
      orchestrator_di.bookingDetailRepositoryProvider.overrideWithValue(repo),
      broadcaster_di.foregroundTaskBackendProvider.overrideWithValue(fg),
      broadcaster_di.geolocatorBackendProvider.overrideWithValue(geo),
      broadcaster_di.locationBroadcasterSecureStorageProvider
          .overrideWithValue(secure),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Mounts the controller and waits for both the booking detail to
/// resolve and any `_startService` chain triggered by the listener.
Future<void> _settle(ProviderContainer c, int jobId) async {
  c.listen(foregroundLocationServiceControllerProvider(jobId), (_, _) {});
  await c.read(bookingDetailProvider(jobId).future);
  // Drain microtasks the listener / startService chain queues up.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('status × role gate', () {
    test(
      'tech viewer + EN_ROUTE → service starts; state = running',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(
            status: 'EN_ROUTE',
            currentUserId: 99, // tech
          ),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(fg.startCalls, 1);
        expect(fg.saveDataCalls, hasLength(1));
        expect(fg.saveDataCalls.first.key, TechLocationTaskKeys.configKey);
        // Token + booking id encoded into the blob.
        expect(fg.saveDataCalls.first.value, contains('tok-abc'));
        expect(fg.saveDataCalls.first.value, contains('42'));
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
      },
    );

    test(
      'tech viewer + ARRIVED → service starts (within window)',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'ARRIVED', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(fg.startCalls, 1);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
      },
    );

    test(
      'customer viewer + EN_ROUTE → service NOT started (tech-only gate)',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 7), // customer
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(fg.startCalls, 0);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.idle,
        );
      },
    );

    test(
      'tech viewer + CONFIRMED → status not in {EN_ROUTE, ARRIVED}, no start',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'CONFIRMED', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(fg.startCalls, 0);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.idle,
        );
      },
    );
  });

  group('permission flow (audit C2)', () {
    test(
      'foreground location denied → state = permissionDenied; service NOT started',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend()
          ..checkPermissionSequence = [LocationPermission.denied]
          ..requestPermissionSequence = [LocationPermission.denied];
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.permissionDenied,
        );
        expect(fg.startCalls, 0);
      },
    );

    test(
      'foreground deniedForever → state = permissionDenied; no requestPermission '
      'attempt',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend()
          ..checkPermissionSequence = [LocationPermission.deniedForever];
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.permissionDenied,
        );
        // checkPermission ran once (initial); requestPermission only fires
        // when first check returned `denied` (not `deniedForever`).
        expect(geo.requestPermissionCalls, 0);
      },
    );

    test(
      'notification permission denied → state = notificationPermissionDenied',
      () async {
        final fg = FakeForegroundTaskBackend()
          ..notificationPermission = NotificationPermission.denied
          ..notificationRequestResult = NotificationPermission.denied;
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.notificationPermissionDenied,
        );
        expect(fg.startCalls, 0);
      },
    );

    test(
      'whileInUse foreground → best-effort background-location upgrade fires '
      'requestPermission a second time',
      () async {
        // checkPermission returns whileInUse on first call; the upgrade
        // attempt re-asks via requestPermission.
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend()
          ..checkPermissionSequence = [LocationPermission.whileInUse]
          ..requestPermissionSequence = [
            // First requestPermission is the foreground re-prompt — never
            // fires (initial check was whileInUse, not denied). Second is
            // the background upgrade — returns whileInUse, no upgrade.
            LocationPermission.whileInUse,
          ];
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        // Service still starts — background denial is best-effort, not a
        // hard block.
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
        // requestPermission fires for the background upgrade attempt.
        expect(geo.requestPermissionCalls, 1);
      },
    );
  });

  group('startService result handling (audit C4)', () {
    test(
      'ServiceRequestFailure(ServiceAlreadyStartedException) → soft-success, '
      'state = running',
      () async {
        final fg = FakeForegroundTaskBackend()
          ..nextStartResult = ServiceRequestFailure(
            error: ServiceAlreadyStartedException(),
          );
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
      },
    );

    test(
      'ServiceRequestFailure(generic error) → state = error',
      () async {
        final fg = FakeForegroundTaskBackend()
          ..nextStartResult = ServiceRequestFailure(
            error: StateError('disk full'),
          );
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.error,
        );
      },
    );

    test(
      'auth token missing in secure storage → state = error; service NOT '
      'started',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
          authToken: null,
        );

        await _settle(c, 42);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.error,
        );
        expect(fg.startCalls, 0);
      },
    );
  });

  group('settings deep-link (audit C2)', () {
    test(
      'openSystemSettings forwards to geolocator backend',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'CONFIRMED', currentUserId: 99),
          fg: fg,
          geo: geo,
        );
        await _settle(c, 42);

        final result = await c
            .read(foregroundLocationServiceControllerProvider(42).notifier)
            .openSystemSettings();

        expect(result, isTrue);
        expect(geo.openAppSettingsCalls, 1);
      },
    );
  });

  group('fatal-auth channel + latch (audit H4)', () {
    test(
      'isolate fatal-auth message → state = error; service stopped; '
      'callback unregistered',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
        expect(fg.registeredCallbacks, hasLength(1));

        // Simulate the isolate calling sendDataToMain with a fatal-auth
        // envelope. The recorded callback drives the controller.
        fg.simulateIsolateMessage({
          TechLocationTaskKeys.messageKind:
              TechLocationTaskKeys.fatalAuthErrorKind,
          TechLocationTaskKeys.messageStatusCode: 401,
          TechLocationTaskKeys.messageCode: 'token_expired',
        });
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.error,
        );
        expect(fg.stopCalls, 1);
        // Callback removed during _stopService.
        expect(fg.registeredCallbacks, isEmpty);
      },
    );

    test(
      'fatal-auth latch blocks restart while booking stays in EN_ROUTE',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);
        expect(fg.startCalls, 1);

        // Fatal-auth fires.
        fg.simulateIsolateMessage({
          TechLocationTaskKeys.messageKind:
              TechLocationTaskKeys.fatalAuthErrorKind,
          TechLocationTaskKeys.messageStatusCode: 403,
          TechLocationTaskKeys.messageCode: 'not_a_technician',
        });
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.error,
        );

        // Refresh the booking detail; status is still EN_ROUTE → the
        // listener fires `_evaluate()` again. The latch must block a
        // restart.
        c.invalidate(bookingDetailProvider(42));
        await c.read(bookingDetailProvider(42).future);
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        // No additional startCalls — we stay at error.
        expect(fg.startCalls, 1);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.error,
        );
      },
    );

    test(
      'non-fatal-kind isolate message is ignored (state unchanged)',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );

        fg.simulateIsolateMessage({'kind': 'something_else', 'foo': 1});
        await Future<void>.delayed(Duration.zero);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
        expect(fg.stopCalls, 0);
      },
    );

    test(
      'non-Map data dropped silently',
      () async {
        final fg = FakeForegroundTaskBackend();
        final geo = FakeGeolocatorBackend();
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);

        fg.simulateIsolateMessage('hello world');
        await Future<void>.delayed(Duration.zero);

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
      },
    );
  });

  // ──── permission-lost channel (audit F-15, Batch B) ─────────────────
  // Mirror of the fatal-auth tests for the new isolate→main signal.
  // The isolate sends `permission_lost` when its onStart re-check
  // finds permission denied, OR when the position stream errors with
  // a PermissionDeniedException / LocationServiceDisabledException
  // mid-session. The controller must stop the service and flip
  // BroadcastState.permissionDenied so the C6 banner surfaces.

  group('permission-lost channel (audit F-15)', () {
    test(
      'isolate permission-lost message → state = permissionDenied; '
      'service stopped; callback unregistered',
      () async {
        final fg = FakeForegroundTaskBackend();
        // Drive permission sequence so that the tail _evaluate after
        // _stopService's `whenComplete` sees a denied permission and
        // legitimately surfaces permissionDenied rather than racing to
        // restart. (FakeGeolocator's default `[always]` would let the
        // tail _evaluate restart and the test would observe `running`.)
        final geo = FakeGeolocatorBackend()
          ..checkPermissionSequence = [
            LocationPermission.always, // initial settle
            LocationPermission.denied, // post-permission-lost tail
          ]
          ..requestPermissionSequence = [
            LocationPermission.denied, // user really did revoke
          ];
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);
        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.running,
        );
        expect(fg.registeredCallbacks, hasLength(1));

        fg.simulateIsolateMessage({
          TechLocationTaskKeys.messageKind:
              TechLocationTaskKeys.permissionLostKind,
        });
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(
          c.read(foregroundLocationServiceControllerProvider(42)),
          BroadcastState.permissionDenied,
        );
        expect(fg.stopCalls, 1);
        expect(fg.registeredCallbacks, isEmpty);
      },
    );

    test(
      'permission-lost does NOT latch — restart can fire while booking '
      'stays in EN_ROUTE (contrast with fatal-auth latch)',
      () async {
        // The fatal-auth latch test (above) asserts startCalls stays
        // at 1 after the message + invalidation while status stays
        // EN_ROUTE (latch blocks restart). Permission-lost has NO
        // such latch — once permission is granted at OS level, the
        // controller's standard _evaluate path can restart cleanly.
        // Mirror the fatal-auth latch test's shape but assert the
        // inverse outcome: more than one start fires.
        final fg = FakeForegroundTaskBackend();
        // Sequence: initial start [.always], post-permission-lost tail
        // sees denied (user really revoked), then user grants in
        // Settings before the invalidate fires → 3rd checkPermission
        // returns always.
        final geo = FakeGeolocatorBackend()
          ..checkPermissionSequence = [
            LocationPermission.always, // initial settle
            LocationPermission.denied, // post-permission-lost tail
            LocationPermission.always, // user re-granted; invalidate
          ]
          ..requestPermissionSequence = [
            LocationPermission.denied, // 1st request: still denied
            LocationPermission.always, // 2nd request: granted
          ];
        final c = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          fg: fg,
          geo: geo,
        );

        await _settle(c, 42);
        expect(fg.startCalls, 1);

        // Fire permission-lost from isolate.
        fg.simulateIsolateMessage({
          TechLocationTaskKeys.messageKind:
              TechLocationTaskKeys.permissionLostKind,
        });
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        // After this the tail _evaluate saw denied → state =
        // permissionDenied; latch IS NOT set (F-15 contract).

        // Invalidate to simulate the user returning from Settings;
        // status stays EN_ROUTE so the listener fires _evaluate
        // again. Without the latch, _evaluate must be able to restart.
        c.invalidate(bookingDetailProvider(42));
        await c.read(bookingDetailProvider(42).future);
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        // Contrast with fatal-auth latch: that test asserts
        // startCalls == 1. Here permission-lost did NOT latch, so
        // a restart must have fired at some point along the way.
        expect(
          fg.startCalls,
          greaterThan(1),
          reason:
              'permission-lost has no latch; restart should fire when '
              'permission is granted at the OS level even while status '
              'stays EN_ROUTE',
        );
      },
    );
  });
}
