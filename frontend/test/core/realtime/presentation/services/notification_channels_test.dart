import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/services/notification_channels.dart';

/// Tests for the `job_dispatch` Android notification channel registration.
///
/// We mock `flutter_local_notifications`' platform channel directly rather
/// than going through `FCMHandler.initialize()`. Reasoning: `initialize()`
/// also touches `firebase_messaging`'s platform channels in ways that
/// would require a full Firebase mock setup; the channel-registration
/// contract is the orthogonal concern these tests exist to pin.
///
/// `FCMHandler.initialize()` calls `ensureJobDispatchChannel()` as its
/// first step, so testing the function directly tests the same code path
/// the production wiring exercises.
void main() {
  // Register the Android platform plugin into
  // `FlutterLocalNotificationsPlatform.instance`. Without this,
  // `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>`
  // returns null in tests because no native plugin auto-registers.
  // Mirrors the package's own android_flutter_local_notifications_test.dart
  // setup.
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── Method-channel intercept ───────────────────────────────────────────
  //
  // The `flutter_local_notifications` plugin marshals every plugin method
  // onto this channel. We capture every call so the tests can assert on
  // method name + argument shape.
  //
  // Platform override: the plugin's
  // `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>`
  // returns `null` unless `defaultTargetPlatform == TargetPlatform.android`.
  // In a vanilla `flutter_test` run on Linux/macOS, that resolution
  // returns null and the channel registration silently no-ops — the
  // tests would then assert on an empty call list. Force-override the
  // platform per test so the Android branch runs.
  const channelName = 'dexterous.com/flutter/local_notifications';
  late List<MethodCall> calls;

  void installHandler(Future<Object?> Function(MethodCall) impl) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), impl);
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    installHandler((call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
    debugDefaultTargetPlatformOverride = null;
  });

  // ─── C1 — call exactly once with the wire-frozen id ───────────────────

  test('C1 — ensureJobDispatchChannel calls createNotificationChannel once '
      'with id "job_dispatch"', () async {
    await ensureJobDispatchChannel();

    final createCalls = calls
        .where((c) => c.method == 'createNotificationChannel')
        .toList();
    expect(
      createCalls,
      hasLength(1),
      reason:
          'a single ensureJobDispatchChannel call must produce exactly '
          'one createNotificationChannel platform call — no retries, no '
          'pre-check that turns into a no-op for the wrong reason',
    );

    final args = createCalls.single.arguments as Map<dynamic, dynamic>;
    expect(
      args['id'],
      'job_dispatch',
      reason:
          'channel id is wire-frozen and must match the manifest '
          'meta-data and AndroidManifest @string resource',
    );
  });

  // ─── C2 — HIGH importance ─────────────────────────────────────────────

  test(
    'C2 — created channel uses HIGH importance (heads-up notifications)',
    () async {
      await ensureJobDispatchChannel();

      final args =
          calls
                  .firstWhere((c) => c.method == 'createNotificationChannel')
                  .arguments
              as Map<dynamic, dynamic>;

      // flutter_local_notifications maps Importance.high → 4 (Android's
      // NotificationManager.IMPORTANCE_HIGH constant). If this changes
      // upstream, the channel would silently downgrade — a tech with phone
      // face-down would stop seeing heads-up job offers.
      expect(
        args['importance'],
        4,
        reason:
            'Importance.high (== Android IMPORTANCE_HIGH == 4) is required '
            'for heads-up rendering; lower importance silently demotes the '
            'channel and breaks face-down notification visibility',
      );
    },
  );

  // ─── C3 — name + description match the resources ──────────────────────

  test(
    'C3 — created channel name and description are user-visible strings',
    () async {
      await ensureJobDispatchChannel();

      final args =
          calls
                  .firstWhere((c) => c.method == 'createNotificationChannel')
                  .arguments
              as Map<dynamic, dynamic>;

      expect(
        args['name'],
        'Job Requests',
        reason: 'channel name is user-visible in OS Settings → Notifications',
      );
      expect(
        args['description'],
        'New job requests, dispatch updates, and time-critical events for technicians.',
        reason:
            'channel description is shown beneath the name in OS Settings; '
            'must explain the channel scope so users make informed mute '
            'decisions',
      );
    },
  );

  // ─── C4 — calling twice produces two platform calls (idempotent on OS) ─

  test('C4 — calling ensureJobDispatchChannel twice produces two platform '
      'calls (Android dedups by id; we do not pre-check in Dart)', () async {
    await ensureJobDispatchChannel();
    await ensureJobDispatchChannel();

    final createCalls = calls
        .where((c) => c.method == 'createNotificationChannel')
        .toList();
    // The Dart-side function has NO pre-check / memoization on purpose:
    // the OS API is genuinely idempotent (same id == same channel) and
    // adding a Dart-side cache would be ceremony that drifts under
    // concurrent calls from main + BG isolates. This test pins that we
    // know about the redundancy and aren't accidentally creating
    // differently-configured duplicates (same id wins).
    expect(
      createCalls,
      hasLength(2),
      reason: 'no Dart-side memoization — relies on Android dedup by id',
    );

    // Both calls use the same id — that's what makes Android's OS-level
    // dedup safe.
    expect(
      createCalls.map((c) => (c.arguments as Map<dynamic, dynamic>)['id']),
      everyElement(equals('job_dispatch')),
    );
  });

  // ─── C5 — platform exception does not propagate ──────────────────────

  test('C5 — platform exception during channel creation does not propagate '
      '(boot must not break on plugin-side failures)', () async {
    installHandler((call) async {
      calls.add(call);
      throw PlatformException(
        code: 'CHANNEL_CREATE_FAILED',
        message: 'simulated OEM-skin failure',
      );
    });

    // Must complete without throwing — caller is FCMHandler.initialize(),
    // which is awaited inside bootAfterAuth, which itself runs
    // fire-and-forget from AuthNotifier.build(). A propagating exception
    // here would surface as an unhandled async error and could route the
    // user to /login (router redirects on AsyncError). WS is the primary
    // channel; we degrade FCM gracefully.
    await expectLater(ensureJobDispatchChannel(), completes);

    // We did still attempt the call — the swallow is in the catch block,
    // not a pre-check.
    expect(
      calls.where((c) => c.method == 'createNotificationChannel'),
      hasLength(1),
    );
  });
}
