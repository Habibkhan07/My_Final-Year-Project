// Unit tests for `TechLocationTaskHandler` — the isolate-side handler
// that runs Geolocator and POSTs each fix to the backend's
// tech-location endpoint.
//
// Covers audit T-3 (deferred under flag #36 from session 4):
//   T-3a  onStart no-op when getData returns null (config absent).
//   T-3b  onStart no-op when config blob is malformed.
//   T-3c  onStart no-op when permission denied.
//   T-3d  onStart no-op when permission deniedForever.
//   T-3e  onStart happy path subscribes to position stream.
//   T-3f  _onFix posts accuracy=null when geolocator reports 0 (audit
//         tolerance: backend accepts either).
//   T-3g  _onFix posts heading=null when headingAccuracy <= 0 (audit
//         H1 / F-4 — fixes the "always-north" bug).
//   T-3h  _onFix on 401 sends fatal_auth_error to main.
//   T-3i  _onFix on 403 sends fatal_auth_error to main.
//   T-3j  _onFix on 5xx swallows error, no message to main.
//   T-3k  _onFix on 429 silently drops, no error.
//   T-3l  _onFix on non-HttpFailure (network) swallows error.
//   T-3m  onDestroy cancels the position subscription + closes the
//         http client.
//   T-3n  encodeConfig / decodeConfig round-trip preserves the auth
//         token + booking id.
//   T-3o  decodeConfig returns null on malformed input variants.
//
// Test seam: handler accepts ports + factories via constructor (audit
// H13 isolate-side refactor, commit c0e010d). Fakes drive
// FlutterForegroundTask.{getData, sendDataToMain} and
// Geolocator.{checkPermission, getPositionStream} synchronously; a
// MockClient drives the HTTP layer.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source.dart';
import 'package:frontend/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../_helpers/fake_isolate_backends.dart';

// ──────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────

/// Flushes pending microtasks. Each `controller.add(position)` puts
/// `_onFix` on a microtask, and `_onFix` itself awaits the in-flight
/// POST through several microtasks. Call this after each
/// `add(position)` to settle side effects before assertions.
Future<void> pumpEventQueue([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Builds a [TechLocationTaskHandler] wired to fakes + a [MockClient]
/// configured via [respond]. The mock client + recorded request list
/// are returned alongside the handler so tests can drive AND inspect.
({
  TechLocationTaskHandler handler,
  FakeIsolateForegroundTaskBackend foregroundTask,
  FakeIsolateGeolocatorBackend geolocator,
  List<http.Request> requests,
  ClosableMockClient client,
})
buildHandler({
  required Future<http.Response> Function(http.Request) respond,
  String? configBlob,
  LocationPermission permission = LocationPermission.always,
}) {
  final foregroundTask = FakeIsolateForegroundTaskBackend()
    ..nextConfigBlob = configBlob;
  final geolocator = FakeIsolateGeolocatorBackend()
    ..nextPermission = permission;
  final requests = <http.Request>[];
  final client = ClosableMockClient((request) async {
    requests.add(request);
    return respond(request);
  });
  final handler = TechLocationTaskHandler(
    foregroundTask: foregroundTask,
    geolocator: geolocator,
    clientFactory: () => client,
    remoteFactory: TechLocationRemoteDataSource.new,
  );
  return (
    handler: handler,
    foregroundTask: foregroundTask,
    geolocator: geolocator,
    requests: requests,
    client: client,
  );
}

/// `MockClient` does not implement `close()` in a way the data source
/// depends on, but the handler invokes `_isolateClient.close()` in
/// onDestroy — wrap so we can assert the close.
class ClosableMockClient extends MockClient {
  bool closed = false;

  ClosableMockClient(super.handler);

  @override
  void close() {
    closed = true;
    super.close();
  }
}


const _validConfig = 'token-abc42';

void main() {
  // ────────── T-3a / T-3b: bad config ─────────────────────────────────

  test('T-3a onStart no-op when getData returns null', () async {
    final h = buildHandler(
      respond: (_) async => fail('client should not be invoked'),
      configBlob: null,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    await pumpEventQueue();

    expect(h.foregroundTask.getDataCalls, [TechLocationTaskKeys.configKey]);
    expect(h.geolocator.checkPermissionCalls, 0);
    expect(h.geolocator.getPositionStreamCalls, isEmpty);
    expect(h.requests, isEmpty);

    await h.geolocator.close();
  });

  test('T-3b onStart no-op when config blob is malformed', () async {
    final h = buildHandler(
      respond: (_) async => fail('client should not be invoked'),
      configBlob: 'no-delimiter-here',
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    await pumpEventQueue();

    expect(h.geolocator.checkPermissionCalls, 0);
    expect(h.geolocator.getPositionStreamCalls, isEmpty);
    expect(h.requests, isEmpty);

    await h.geolocator.close();
  });

  // ────────── T-3c / T-3d: permission gates ───────────────────────────

  test('T-3c onStart no-op when permission denied', () async {
    final h = buildHandler(
      respond: (_) async => fail('client should not be invoked'),
      configBlob: _validConfig,
      permission: LocationPermission.denied,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    await pumpEventQueue();

    expect(h.geolocator.checkPermissionCalls, 1);
    expect(h.geolocator.getPositionStreamCalls, isEmpty);
    expect(h.requests, isEmpty);

    await h.geolocator.close();
  });

  test('T-3d onStart no-op when permission deniedForever', () async {
    final h = buildHandler(
      respond: (_) async => fail('client should not be invoked'),
      configBlob: _validConfig,
      permission: LocationPermission.deniedForever,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    await pumpEventQueue();

    expect(h.geolocator.getPositionStreamCalls, isEmpty);
    expect(h.requests, isEmpty);

    await h.geolocator.close();
  });

  // ────────── T-3e: happy path subscribe + POST ───────────────────────

  test(
    'T-3e onStart happy path subscribes to position stream and POSTs '
    'each fix with auth header + correct URL',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      expect(h.geolocator.getPositionStreamCalls, hasLength(1));
      // LocationSettings configured for high accuracy / 10m filter.
      final settings = h.geolocator.getPositionStreamCalls.first!;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 10);

      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();

      expect(h.requests, hasLength(1));
      final req = h.requests.first;
      expect(
        req.url.path.endsWith('/bookings/42/tech-location/'),
        isTrue,
        reason: 'URL should target the booking id from the config blob',
      );
      expect(req.method, 'POST');
      expect(req.headers['Authorization'], 'Token token-abc');
      expect(req.headers['Content-Type'], 'application/json');

      await h.geolocator.close();
    },
  );

  // ────────── T-3f: accuracy <= 0 → null wire field ───────────────────

  test(
    'T-3f _onFix sends accuracy=null when geolocator reports 0',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition(accuracy: 0.0));
      await pumpEventQueue();

      final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
      expect(
        body.containsKey('accuracy_meters') &&
            body['accuracy_meters'] != null,
        isFalse,
        reason:
            'accuracy=0 from geolocator means "unknown"; wire payload '
            'should omit/null it',
      );

      await h.geolocator.close();
    },
  );

  test('T-3f _onFix sends accuracy=value when geolocator reports >0', () async {
    final h = buildHandler(
      respond: (_) async => http.Response('', 200),
      configBlob: _validConfig,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    h.geolocator.positionController.add(fakePosition(accuracy: 12.5));
    await pumpEventQueue();

    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    expect(body['accuracy_meters'], 12.5);

    await h.geolocator.close();
  });

  // ────────── T-3g: headingAccuracy <= 0 → null heading (audit H1) ────

  test(
    'T-3g _onFix sends heading=null when headingAccuracy <= 0 (audit '
    'H1: fixes always-north bug for stationary techs)',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      // headingAccuracy=0 means "device cannot report heading" even
      // though heading itself is 0.0 (which would be misread as
      // facing-north under a `>= 0` check).
      h.geolocator.positionController.add(
        fakePosition(heading: 0.0, headingAccuracy: 0.0),
      );
      await pumpEventQueue();

      final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
      expect(
        body.containsKey('heading') && body['heading'] != null,
        isFalse,
        reason:
            'headingAccuracy<=0 should null out heading regardless of '
            'the heading value',
      );

      await h.geolocator.close();
    },
  );

  test(
    'T-3g _onFix sends heading=value when headingAccuracy > 0',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(
        fakePosition(heading: 135.7, headingAccuracy: 5.0),
      );
      await pumpEventQueue();

      final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
      expect(body['heading'], 135.7);

      await h.geolocator.close();
    },
  );

  // ────────── T-3h / T-3i: fatal-auth signalling ──────────────────────

  test('T-3h _onFix on 401 sends fatal_auth_error to main', () async {
    final h = buildHandler(
      respond: (_) async => http.Response(
        jsonEncode({
          'code': 'authentication_failed',
          'message': 'Token expired',
        }),
        401,
      ),
      configBlob: _validConfig,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    h.geolocator.positionController.add(fakePosition());
    await pumpEventQueue();

    expect(h.foregroundTask.sentToMain, hasLength(1));
    final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
    expect(msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.fatalAuthErrorKind);
    expect(msg[TechLocationTaskKeys.messageStatusCode], 401);
    expect(msg[TechLocationTaskKeys.messageCode], 'authentication_failed');

    await h.geolocator.close();
  });

  test('T-3i _onFix on 403 sends fatal_auth_error to main', () async {
    final h = buildHandler(
      respond: (_) async => http.Response(
        jsonEncode({
          'code': 'permission_denied',
          'message': 'Not the assigned tech',
        }),
        403,
      ),
      configBlob: _validConfig,
    );

    await h.handler.onStart(DateTime.now(), TaskStarter.developer);
    h.geolocator.positionController.add(fakePosition());
    await pumpEventQueue();

    expect(h.foregroundTask.sentToMain, hasLength(1));
    final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
    expect(msg[TechLocationTaskKeys.messageStatusCode], 403);
    expect(msg[TechLocationTaskKeys.messageCode], 'permission_denied');

    await h.geolocator.close();
  });

  // ────────── T-3j / T-3k / T-3l: transient / silent paths ────────────

  test(
    'T-3j _onFix on 5xx logs but does NOT signal main (transient)',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('upstream broken', 503),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();

      expect(h.foregroundTask.sentToMain, isEmpty);
      // Stream subscription must still be alive — second fix should
      // still attempt the POST.
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();
      expect(h.requests, hasLength(2));

      await h.geolocator.close();
    },
  );

  test(
    'T-3k _onFix on 429 silently drops (returns false from data source)',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 429),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();

      // Neither side-channel fires — no fatal-auth, no exception.
      expect(h.foregroundTask.sentToMain, isEmpty);
      expect(h.requests, hasLength(1));

      await h.geolocator.close();
    },
  );

  test(
    'T-3l _onFix swallows non-HttpFailure exceptions (e.g. network)',
    () async {
      final h = buildHandler(
        // Throwing a non-HttpFailure (the data source's network branch
        // wraps SocketException → HttpFailure, but a true unexpected
        // exception path also exists — simulate via TimeoutException
        // unwrapped). The data source's timeout wraps to HttpFailure
        // with statusCode=0 — that's still an HttpFailure with
        // 0 ∉ {401, 403}, so it lands in the "transient" branch.
        // For the catch (e) branch we need something else entirely.
        respond: (_) async => throw StateError('synthetic error'),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();

      // Must not crash, must not signal main.
      expect(h.foregroundTask.sentToMain, isEmpty);

      await h.geolocator.close();
    },
  );

  // ────────── T-3m: dispose path ──────────────────────────────────────

  test(
    'T-3m onDestroy cancels position subscription and closes http client',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();
      expect(h.requests, hasLength(1));

      await h.handler.onDestroy(DateTime.now(), false);
      expect(h.client.closed, isTrue);

      // After destroy, further pushes to the controller should NOT
      // produce new POSTs — subscription is cancelled.
      h.geolocator.positionController.add(fakePosition());
      await pumpEventQueue();
      expect(h.requests, hasLength(1));

      await h.geolocator.close();
    },
  );

  // ────────── T-3n: encode/decode round-trip ──────────────────────────

  test(
    'T-3n encodeConfig / decodeConfig round-trips token + booking id',
    () {
      final encoded = TechLocationTaskKeys.encodeConfig(
        authToken: 'abcdef-1234567890',
        bookingId: 42,
      );
      final decoded = TechLocationTaskKeys.decodeConfig(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.authToken, 'abcdef-1234567890');
      expect(decoded.bookingId, 42);
    },
  );

  // ────────── T-3o: decodeConfig rejects malformed input ──────────────

  test('T-3o decodeConfig returns null on malformed input', () {
    // Missing delimiter → only 1 part.
    expect(TechLocationTaskKeys.decodeConfig('justtoken'), isNull);
    // Empty token half.
    expect(TechLocationTaskKeys.decodeConfig('42'), isNull);
    // Non-numeric booking id.
    expect(TechLocationTaskKeys.decodeConfig('tokenabc'), isNull);
    // Negative booking id (rejected explicitly).
    expect(TechLocationTaskKeys.decodeConfig('token-1'), isNull);
    // Too many delimiters → split yields >2 parts.
    expect(
      TechLocationTaskKeys.decodeConfig('token42extra'),
      isNull,
    );
  });

  // ────────── T-3p / T-3q: F-15 permission_lost signalling ────

  test(
    'T-3p (F-15) onStart with permission denied sends permission_lost to main',
    () async {
      final h = buildHandler(
        respond: (_) async => fail('client should not be invoked'),
        configBlob: _validConfig,
        permission: LocationPermission.denied,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);

      expect(h.foregroundTask.sentToMain, hasLength(1));
      final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
      expect(
        msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.permissionLostKind,
      );
      // No POST should have fired and no position stream subscription
      // should be active.
      expect(h.requests, isEmpty);
      expect(h.geolocator.getPositionStreamCalls, isEmpty);

      await h.geolocator.close();
    },
  );

  test(
    'T-3p2 (F-15) onStart with permission deniedForever also sends '
    'permission_lost',
    () async {
      final h = buildHandler(
        respond: (_) async => fail('client should not be invoked'),
        configBlob: _validConfig,
        permission: LocationPermission.deniedForever,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);

      expect(h.foregroundTask.sentToMain, hasLength(1));
      final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
      expect(
        msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.permissionLostKind,
      );

      await h.geolocator.close();
    },
  );

  test(
    'T-3q (F-15) position stream PermissionDeniedException sends permission_lost',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('{}', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      // Mid-session permission revocation: Geolocator surfaces the
      // exception via the stream's error channel.
      h.geolocator.positionController.addError(
        const PermissionDeniedException('revoked mid-session'),
      );
      await pumpEventQueue();

      expect(h.foregroundTask.sentToMain, hasLength(1));
      final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
      expect(
        msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.permissionLostKind,
      );

      await h.geolocator.close();
    },
  );

  test(
    'T-3q2 (F-15) position stream LocationServiceDisabledException sends '
    'permission_lost',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('{}', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.addError(
        const LocationServiceDisabledException(),
      );
      await pumpEventQueue();

      expect(h.foregroundTask.sentToMain, hasLength(1));
      final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
      expect(
        msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.permissionLostKind,
      );

      await h.geolocator.close();
    },
  );

  test(
    'T-3q3 (F-15) position stream non-permission errors do NOT send '
    'permission_lost',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('{}', 200),
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      // Some other exception type — should be logged but NOT signaled.
      h.geolocator.positionController.addError(
        const FormatException('unexpected stream error'),
      );
      await pumpEventQueue();

      expect(h.foregroundTask.sentToMain, isEmpty);

      await h.geolocator.close();
    },
  );

  // ────────── T-3r: F-20 in-flight POST guard ─────────

  test(
    'T-3r (F-20) second fix is dropped while first POST is in flight',
    () async {
      // Use a Completer so the first POST hangs until we explicitly
      // unblock it. While it's hanging, push a second position; the
      // handler must drop it (no second request).
      final responseGate = Completer<http.Response>();
      var requestCount = 0;
      final h = buildHandler(
        respond: (_) async {
          requestCount++;
          return responseGate.future;
        },
        configBlob: _validConfig,
      );

      await h.handler.onStart(DateTime.now(), TaskStarter.developer);
      h.geolocator.positionController.add(fakePosition());
      // Let the listen-callback fire and reach the await on POST.
      await pumpEventQueue();
      expect(requestCount, 1);

      // Second emission while first is in flight — should be dropped.
      h.geolocator.positionController.add(fakePosition(lat: 31.6, lng: 74.4));
      await pumpEventQueue();
      expect(requestCount, 1, reason: 'second fix must be dropped');

      // Unblock the first POST; subsequent emissions must POST again.
      responseGate.complete(http.Response('{}', 200));
      await pumpEventQueue();

      h.geolocator.positionController.add(fakePosition(lat: 31.7, lng: 74.5));
      await pumpEventQueue();
      expect(
        requestCount,
        2,
        reason: 'after in-flight clears, the next fix must POST',
      );

      await h.geolocator.close();
    },
  );

  // ────────── T-3s: notification-tap deep link (audit Batch H) ────────

  test(
    'T-3s (Batch H) onNotificationPressed sends open_booking envelope '
    'and calls launchApp',
    () async {
      final h = buildHandler(
        respond: (_) async => http.Response('{}', 200),
        configBlob: _validConfig,
      );

      // Bring the handler into a started state so `_bookingId` is
      // populated. T-3n's encode/decode round-trip pins the format
      // we rely on here.
      await h.handler.onStart(DateTime.now(), TaskStarter.developer);

      // Simulate the package's notification-tap callback.
      h.handler.onNotificationPressed();

      // Envelope: kind = open_booking, booking_id = the parsed config blob's id.
      expect(h.foregroundTask.sentToMain, hasLength(1));
      final msg = h.foregroundTask.sentToMain.single as Map<String, Object?>;
      expect(
        msg[TechLocationTaskKeys.messageKind],
        TechLocationTaskKeys.openBookingKind,
      );
      // _validConfig encodes booking_id=42; the handler captures it on onStart.
      expect(msg[TechLocationTaskKeys.messageBookingId], 42);

      // launchApp called once with no route (we rely on sendDataToMain
      // for navigation; launchApp just brings the app to foreground).
      expect(h.foregroundTask.launchAppCalls, [null]);

      await h.geolocator.close();
    },
  );

  test(
    'T-3s2 (Batch H) onNotificationPressed before onStart is a no-op '
    '(no envelope, no launchApp)',
    () async {
      // Defensive: if the package fires onNotificationPressed before
      // onStart somehow (notification re-displayed across a service
      // restart, etc.), `_bookingId` is still -1. Sending an envelope
      // with -1 would route to a malformed `/booking/-1` URL.
      final h = buildHandler(
        respond: (_) async => fail('client should not be invoked'),
        configBlob: _validConfig,
      );

      // Don't call onStart. _bookingId stays at its -1 sentinel.
      h.handler.onNotificationPressed();

      expect(h.foregroundTask.sentToMain, isEmpty);
      expect(h.foregroundTask.launchAppCalls, isEmpty);

      await h.geolocator.close();
    },
  );
}
