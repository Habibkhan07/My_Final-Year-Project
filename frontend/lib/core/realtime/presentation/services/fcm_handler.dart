import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/event_local_data_source.dart';
import '../../data/mappers/system_event_mapper.dart';
import '../../data/models/system_event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../notifiers/event_sync_notifier.dart';
import '../notifiers/system_event_notifier.dart';
import 'notification_channels.dart';

/// Main-isolate companion to [firebaseMessagingBackgroundHandler].
///
/// Responsibilities:
///   - Ask for notification permission (best-effort — silent failure is OK
///     because the WebSocket is our primary channel and FCM is a fallback).
///   - Register + re-register this device's token with the backend.
///   - Listen for foreground messages, normalize FCM's string-serialized
///     payloads, and feed them into [SystemEventNotifier].
///   - Handle tap-to-open from background/terminated state.
///   - Drain the background-isolate queue on resume.
///   - Unregister the token on logout.
///
/// Intentionally a plain class (not a Notifier): FCM has no observable
/// state the UI cares about, and the app orchestrator in session 4 owns
/// the lifetime of this instance.
class FCMHandler {
  final SystemEventNotifier _eventNotifier;
  final EventSyncNotifier _syncNotifier;
  final EventRepository _repository;
  final EventLocalDataSource _localDataSource;

  String? _currentToken;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;

  @visibleForTesting
  String? get debugCurrentToken => _currentToken;

  @visibleForTesting
  set debugCurrentToken(String? value) => _currentToken = value;

  static const _logName = 'core.presentation.fcm_handler';

  FCMHandler({
    required SystemEventNotifier eventNotifier,
    required EventSyncNotifier syncNotifier,
    required EventRepository repository,
    required EventLocalDataSource localDataSource,
  })  : _eventNotifier = eventNotifier,
        _syncNotifier = syncNotifier,
        _repository = repository,
        _localDataSource = localDataSource;

  /// Idempotent wiring. Call exactly once on app start, after
  /// `Firebase.initializeApp()` has completed in the main isolate.
  ///
  /// `ensureJobDispatchChannel` runs FIRST so the OS channel exists
  /// before any FCM listener can deliver a notification — a race we
  /// cannot otherwise close cleanly. See `notification_channels.dart`.
  Future<void> initialize() async {
    await ensureJobDispatchChannel();
    await requestPermission();
    await _registerToken();
    _listenForegroundMessages();
    await _setupBackgroundTapHandlers();
    await processPendingBackgroundEvents();
  }

  Future<void> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        log(
          'FCM permission denied; continuing — WS is primary, FCM is fallback',
          name: _logName,
        );
      }
    } catch (e, stack) {
      log(
        'requestPermission failed (continuing): $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  Future<void> _registerToken() async {
    try {
      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken != null) {
        await _repository.registerDevice(
          _currentToken!,
          Platform.isIOS ? 'ios' : 'android',
        );
      }
    } catch (e, stack) {
      log(
        '_registerToken failed (will retry on token refresh): $e',
        name: _logName,
        stackTrace: stack,
      );
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _currentToken = token;
      try {
        await _repository.registerDevice(
          token,
          Platform.isIOS ? 'ios' : 'android',
        );
      } catch (e, stack) {
        log(
          'token refresh register failed: $e',
          name: _logName,
          stackTrace: stack,
        );
      }
    });
  }

  void _listenForegroundMessages() {
    _foregroundSub?.cancel();
    // We do NOT show a local notification here. The Urgency Router already
    // surfaces UI for high-urgency (route push) and low-urgency (banner)
    // events. A local notification on top would double-render.
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      processRemoteMessage(message.data);
    });
  }

  Future<void> _setupBackgroundTapHandlers() async {
    _openedAppSub?.cancel();
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      processRemoteMessage(message.data);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      processRemoteMessage(initial.data);
    }
  }

  /// Normalizes FCM's string-serialized payload, maps to a [SystemEventEntity]
  /// and feeds it through the same ingestion funnel as WebSocket frames.
  ///
  /// CRITICAL: FCM data payloads are string-typed — the nested `payload`
  /// field arrives as a JSON string, not a Map. We detect that and decode
  /// before handing off to the model.
  ///
  /// Visible for testing so unit tests can drive the normalization path
  /// without standing up `FirebaseMessaging.onMessage` streams.
  @visibleForTesting
  void processRemoteMessage(Map<String, dynamic> rawData) {
    try {
      final normalized = Map<String, dynamic>.from(rawData);
      final payloadField = normalized['payload'];
      if (payloadField is String && payloadField.isNotEmpty) {
        normalized['payload'] = jsonDecode(payloadField);
      }

      final model = SystemEventModel.fromJson(normalized);
      final entity = model.toDomain();
      if (entity == null) return;
      // FCM payloads can be hours stale (tray notification tapped after
      // the SLA window). Tag as `fcm` so the notifier's expiry filter
      // uses the WS-anchored server-time estimate instead of this
      // (potentially stale) timestamp.
      _eventNotifier.processEvent(entity, source: SystemEventSource.fcm);
    } catch (e, stack) {
      log(
        'Failed to process FCM message: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Drains the queue that the background isolate wrote into SharedPreferences
  /// while the app was terminated. Called once on resume/launch by [initialize].
  ///
  /// After the queue drains we trigger a REST reconcile — FCM is lossy, so
  /// even a "successful" background drain may be missing events the server
  /// knows about. This matches the post-connect behaviour on the WS side.
  Future<void> processPendingBackgroundEvents() async {
    try {
      final pending = await _localDataSource.consumePendingBackgroundEvents();
      for (final data in pending) {
        processRemoteMessage(data);
      }
      await _syncNotifier.syncMissedEvents();
    } catch (e, stack) {
      log(
        'processPendingBackgroundEvents failed: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Called on logout. Best-effort — repository swallows failures because
  /// the backend reconciles stale tokens server-side eventually.
  Future<void> unregister() async {
    if (_currentToken != null) {
      await _repository.unregisterDevice(_currentToken!);
    }
    _currentToken = null;
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedAppSub = null;
    _tokenRefreshSub = null;
  }
}
