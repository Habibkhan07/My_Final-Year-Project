// Tech-side foreground GPS broadcaster controller.
//
// Lifecycle:
//   • Watches `bookingDetailProvider(jobId)` — when (status × role)
//     enters {EN_ROUTE, ARRIVED} for a technician viewer, starts the
//     foreground service. When status leaves OR screen pops, stops.
//   • The orchestrator screen `ref.watch`-es this provider in its
//     build (alongside the existing event notifiers) — `keepAlive: false`
//     means popping the screen disposes the provider, which auto-stops
//     the service via the dispose hook.
//
// SECURITY: this controller writes the auth token to FlutterForegroundTask's
// shared-prefs blob (so the isolate can authenticate POSTs). The token is
// also in flutter_secure_storage already; the prefs blob is the SAME
// trust boundary because both are stored on-device with no remote
// readback. When the service stops, the blob stays — but it's overwritten
// on every start (so a tech who logs out and a different tech logs in
// will write a fresh token).

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../orchestrator/domain/entities/booking_detail.dart';
import '../../../../orchestrator/domain/entities/booking_orchestrator_role.dart';
import '../../../../orchestrator/presentation/providers/booking_detail_provider.dart';
import '../../domain/entities/broadcast_state.dart';
import '../services/foreground_task_handler.dart';
import 'dependency_injection.dart';

part 'foreground_location_service_controller.g.dart';

/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)
@Riverpod(keepAlive: false)
class ForegroundLocationServiceController
    extends _$ForegroundLocationServiceController {
  static const _kSubscribableStatuses = <BookingStatus>{
    BookingStatus.enRoute,
    BookingStatus.arrived,
  };
  static const _kAuthTokenStorageKey = 'auth_token';
  static const _kNotificationChannelId = 'tech_location_tracking';
  static const _kNotificationChannelName = 'Tracking job';
  static const _kLogName = 'feature.location_broadcaster';

  bool _running = false;

  @override
  BroadcastState build(int jobId) {
    ref.listen(bookingDetailProvider(jobId), (previous, next) {
      next.whenData((booking) async {
        final shouldRun =
            booking.viewerRole == BookingOrchestratorRole.technician &&
            _kSubscribableStatuses.contains(booking.status);

        if (shouldRun && !_running) {
          await _startService(booking);
        } else if (!shouldRun && _running) {
          await _stopService();
        }
      });
    });

    ref.onDispose(() {
      // Fire-and-forget: stopService is async but we cannot await
      // inside onDispose. The platform call is fast (≤100ms typical)
      // and idempotent — calling stop on a stopped service is safe.
      if (_running) {
        unawaited(FlutterForegroundTask.stopService());
        _running = false;
      }
    });

    return BroadcastState.idle;
  }

  Future<void> _startService(BookingDetail booking) async {
    // SECURITY: tech_profile gate is server-side; we additionally
    // gate this controller on viewerRole == technician above.
    final permission = await _ensurePermissions();
    if (permission != BroadcastState.idle &&
        permission != BroadcastState.running) {
      state = permission;
      return;
    }

    final token = await ref
        .read(locationBroadcasterSecureStorageProvider)
        .read(key: _kAuthTokenStorageKey);
    if (token == null || token.isEmpty) {
      developer.log(
        'No auth token in secure storage — cannot start tracking.',
        name: _kLogName,
        level: 1000,
      );
      state = BroadcastState.error;
      return;
    }

    // AndroidNotificationOptions is NOT a const constructor; the
    // class instantiates non-const default values (e.g. visibility
    // wrapper). Build it normally.
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _kNotificationChannelId,
        channelName: _kNotificationChannelName,
        channelDescription:
            'Sends your live location to the customer for the active job.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Geolocator's getPositionStream is the heartbeat — we don't
        // need flutter_foreground_task's onRepeatEvent to fire.
        // (`ForegroundTaskOptions` is const-eligible but
        // `ForegroundTaskEventAction.nothing()` constructs a non-const
        // instance, so the wrapper is non-const too.)
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // saveData BEFORE startService — the isolate reads it on onStart.
    final config = TechLocationTaskKeys.encodeConfig(
      authToken: token,
      bookingId: booking.id,
    );
    await FlutterForegroundTask.saveData(
      key: TechLocationTaskKeys.configKey,
      value: config,
    );

    final firstName = booking.customer.fullName.split(' ').first;
    final result = await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'Tracking job',
      notificationText: 'Sending your location to $firstName',
      callback: startTechLocationTaskCallback,
    );

    if (result is ServiceRequestSuccess) {
      _running = true;
      state = BroadcastState.running;
    } else {
      developer.log(
        'startService failed: $result',
        name: _kLogName,
        level: 1000,
      );
      state = BroadcastState.error;
    }
  }

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
    _running = false;
    state = BroadcastState.idle;
  }

  /// Ensures location + (Android 13+) notification permissions are
  /// granted. Returns:
  ///   • BroadcastState.idle — green-light to start.
  ///   • BroadcastState.permissionDenied — location denied.
  ///   • BroadcastState.notificationPermissionDenied — notification denied.
  ///
  /// The orchestrator screen is expected to surface a friendly explainer
  /// dialog when state flips to a denied variant.
  Future<BroadcastState> _ensurePermissions() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return BroadcastState.permissionDenied;
    }

    final notifGranted =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifGranted != NotificationPermission.granted) {
      final requested =
          await FlutterForegroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        return BroadcastState.notificationPermissionDenied;
      }
    }

    return BroadcastState.idle;
  }
}
