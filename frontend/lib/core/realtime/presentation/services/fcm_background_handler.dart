import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_channels.dart';

/// Top-level entry point invoked by Firebase when an FCM message arrives
/// while the app is terminated or backgrounded.
///
/// Runs in a **separate Dart isolate**. None of the following are available
/// here: Riverpod container, ProviderScope, GoRouter, any Notifier, any
/// live service singletons. The only legal persistence is a freshly-created
/// [SharedPreferences] instance from inside this function.
///
/// ─── CRITICAL COUPLING ──────────────────────────────────────────────────
/// The literal [_kPendingBackgroundEventsKey] MUST match
/// `EventLocalDataSource._keyPendingBackgroundEvents` (currently
/// `'event_sync_pending_bg_events'`). If you change one, change both —
/// otherwise background-queued events silently never reach the main isolate
/// on app resume.
///
/// [_kMaxPendingBackgroundEvents] MUST match
/// `EventLocalDataSource._kMaxPendingBackgroundEvents`. Both isolates
/// apply the same FIFO cap so a wedged FCM init in the main isolate
/// can't let the BG isolate grow the queue past the documented bound
/// (and vice versa).
/// ────────────────────────────────────────────────────────────────────────
const _kPendingBackgroundEventsKey = 'event_sync_pending_bg_events';
const _kMaxPendingBackgroundEvents = 50;

const _logName = 'core.presentation.fcm_bg_handler';

/// Firebase requires background handlers to be top-level functions annotated
/// with `@pragma('vm:entry-point')` so they are preserved by tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized for this isolate. Safe to call again even
  // if main() already initialized the default app — the SDK idempotently
  // returns the existing app instance.
  try {
    await Firebase.initializeApp();
  } catch (e, stack) {
    log(
      'Firebase.initializeApp() failed in background isolate: $e',
      name: _logName,
      stackTrace: stack,
    );
    // Continue — SharedPreferences does not depend on Firebase.
  }

  // Defensive channel registration in the BG isolate. The main isolate's
  // FCMHandler.initialize() is the primary registration site, but on a
  // fresh-install device that receives a push before ever opening the
  // app, the BG isolate is the first (and so far only) Dart VM to run.
  // Without this, the very first notification on a fresh install would
  // route to Android's default unnamed channel.
  //
  // Idempotent on the OS side — same channel id from any isolate
  // converges on a single OS-level NotificationChannel. The function
  // itself wraps platform exceptions internally (see notification_channels.dart).
  await ensureJobDispatchChannel();

  try {
    final prefs = await SharedPreferences.getInstance();
    final existingRaw = prefs.getString(_kPendingBackgroundEventsKey);
    final List<dynamic> queue = existingRaw != null && existingRaw.isNotEmpty
        ? (jsonDecode(existingRaw) as List<dynamic>)
        : <dynamic>[];

    queue.add(message.data);

    // FIFO cap: same bound the main isolate applies in
    // `EventLocalDataSource.savePendingBackgroundEvent`. Drop oldest
    // entries when the queue exceeds the cap. Anything dropped is
    // recoverable via the WS reconnect's `/sync/?since=` catch-up.
    if (queue.length > _kMaxPendingBackgroundEvents) {
      final overflow = queue.length - _kMaxPendingBackgroundEvents;
      queue.removeRange(0, overflow);
    }

    await prefs.setString(_kPendingBackgroundEventsKey, jsonEncode(queue));
  } catch (e, stack) {
    // Best-effort. If the write fails the event is lost for the background
    // queue — but the next WebSocket reconnect + `/events/sync/` will
    // recover it server-side anyway, so we never escalate this to the user.
    log(
      'Failed to queue background FCM message: $e',
      name: _logName,
      stackTrace: stack,
    );
  }
}
