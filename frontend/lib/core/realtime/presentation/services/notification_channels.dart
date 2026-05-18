import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wire-frozen channel id. Referenced from `AndroidManifest.xml` via the
/// `default_notification_channel_id` meta-data and the
/// `@string/default_notification_channel_id` resource — keep all three in
/// sync.
///
/// Changing this id after first install creates a second visible channel
/// in OS notification settings (Android keys channels by id, not by
/// name). The migration path is: call
/// `deleteNotificationChannel('job_dispatch')` first, then create the
/// new id. Don't rename casually.
const String jobDispatchChannelId = 'job_dispatch';

/// Single source of truth for the `job_dispatch` channel's properties.
/// Used by both the main isolate (`FCMHandler.initialize`) and the
/// background isolate (`firebaseMessagingBackgroundHandler`) so the two
/// registrations cannot drift out of sync.
///
/// Importance: HIGH so Android renders a heads-up notification — a
/// technician with phone face-down still sees incoming job offers. Only
/// the user can lower this after first creation; the system caches their
/// override and our code can no longer raise it.
///
/// Channel name and description are user-visible in OS Settings →
/// Notifications. English-only for now; Urdu localization is a separate
/// i18n workstream.
///
/// Caveat (display-name caching): Android caches the channel name on
/// first creation. Devices that already created `job_dispatch` under a
/// previous name continue to show the previous name in OS Settings until
/// the channel is deleted and recreated (`deleteNotificationChannel` →
/// `createNotificationChannel`) or the app is reinstalled. Fresh installs
/// pick up the current name immediately.
const AndroidNotificationChannel
jobDispatchChannel = AndroidNotificationChannel(
  jobDispatchChannelId,
  'Karigar Notifications',
  description:
      'Booking updates, dispatch alerts, payments, and time-critical messages.',
  importance: Importance.high,
);

/// Idempotent channel registration. Called from both the main isolate
/// (early in `FCMHandler.initialize`) and the background isolate
/// (top of `firebaseMessagingBackgroundHandler`).
///
/// Safe to call repeatedly: Android's `createNotificationChannel` is a
/// no-op when the channel id already exists. Cross-isolate calls
/// converge on a single OS-level NotificationChannel.
///
/// Wraps the platform call in try/catch so a plugin-side exception
/// cannot break boot — channel-less notifications still display, just on
/// the OS-managed default channel, and the WS path remains unaffected.
Future<void> ensureJobDispatchChannel() async {
  try {
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(jobDispatchChannel);
  } catch (e, stack) {
    log(
      'ensureJobDispatchChannel failed (continuing): $e',
      name: 'core.presentation.notification_channels',
      stackTrace: stack,
    );
  }
}
