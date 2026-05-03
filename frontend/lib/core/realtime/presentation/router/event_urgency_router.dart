import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/event_urgency.dart';
import '../../domain/entities/system_event_entity.dart';
import '../../domain/entities/system_event_type.dart';
import '../../domain/entities/target_role.dart';
import '../notifiers/event_sync_notifier.dart';

/// Listener-style router that reacts to each event emitted by
/// `systemEventNotifierProvider`.
///
/// NOT a Notifier. Owned by the App Lifecycle Orchestrator (session 4),
/// which calls [handleEvent] from inside `ref.listen(systemEventNotifier, ...)`.
///
/// Why not a provider: a provider would fire from `build()` on first read,
/// but routing depends on the current navigator stack which only exists
/// after the widget tree is mounted. Keeping this as an externally-driven
/// class makes the wiring explicit.
class EventUrgencyRouter {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  static const _bannerAutoDismiss = Duration(seconds: 5);

  const EventUrgencyRouter({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  // ─── Route tables ──────────────────────────────────────────────────────

  // `SystemEventType.jobNewRequest` is intentionally absent. It is presented
  // by `IncomingJobSheetHost` (a global bottom-sheet overlay mounted at the
  // app shell) — a queue-state-driven surface, not a route push. Dropping it
  // from this map removes the previous list-route plumbing entirely; the
  // queue notifier's `ref.listen(systemEventProvider, ...)` is now the only
  // thing that reacts to a `job_new_request` event on the presentation side.
  static const _highUrgencyRoutes = <SystemEventType, String>{
    SystemEventType.jobAccepted: '/customer/job-accepted',
    SystemEventType.quoteGenerated: '/customer/incoming-quote',
    SystemEventType.quoteApproved: '/technician/quote-approved',
    SystemEventType.jobCompleted: '/shared/job-completed',
    SystemEventType.disputeOpened: '/shared/dispute-details',
    SystemEventType.disputeResolved: '/shared/dispute-resolved',
  };

  static const _lowUrgencyTapRoutes = <SystemEventType, String>{
    SystemEventType.techEnRoute: '/customer/track-technician',
    SystemEventType.techArrived: '/customer/track-technician',
    SystemEventType.chatMessage: '/shared/chat',
    SystemEventType.paymentReceived: '/shared/wallet',
    SystemEventType.walletLowBalance: '/shared/wallet',
    SystemEventType.bookingRejected: '/customer/booking/:job_id',
  };

  /// Per-event-type payload key whose value should be substituted into
  /// the matching `:<key>` token in the low-urgency tap route. Mirrors
  /// the high-urgency [_navGuardPayloadKeys] mechanism but for path
  /// templating instead of "already viewing this entity" detection.
  ///
  /// Entries are optional — events without a key fall through and the
  /// raw template path is pushed unchanged (the existing static-path
  /// behavior is preserved).
  static const _lowUrgencyTapPayloadKeys = <SystemEventType, String>{
    SystemEventType.bookingRejected: 'job_id',
  };

  static const _bannerIcons = <SystemEventType, IconData>{
    SystemEventType.chatMessage: Icons.chat_bubble,
    SystemEventType.techEnRoute: Icons.location_on,
    SystemEventType.techArrived: Icons.location_on,
    SystemEventType.paymentReceived: Icons.account_balance_wallet,
    SystemEventType.walletLowBalance: Icons.account_balance_wallet_outlined,
    SystemEventType.bookingRejected: Icons.event_busy,
  };

  static const _bannerTitles = <SystemEventType, String>{
    SystemEventType.chatMessage: 'New Message',
    SystemEventType.techEnRoute: 'Technician On The Way',
    SystemEventType.techArrived: 'Technician Arrived',
    SystemEventType.paymentReceived: 'Payment Received',
    SystemEventType.walletLowBalance: 'Low Wallet Balance',
    SystemEventType.bookingRejected: 'Booking unavailable',
  };

  /// Per-event-type payload key used to detect "already viewing this exact
  /// entity" for the nav guard. Types not in the map skip the guard and
  /// always push — the guard is an optimization, not a correctness gate.
  static const _navGuardPayloadKeys = <SystemEventType, String>{
    SystemEventType.jobAccepted: 'job_id',
    SystemEventType.quoteGenerated: 'quote_id',
    SystemEventType.quoteApproved: 'quote_id',
    SystemEventType.jobCompleted: 'job_id',
    SystemEventType.disputeOpened: 'dispute_id',
    SystemEventType.disputeResolved: 'dispute_id',
  };

  /// Events whose target route is a **list view** rather than a per-entity
  /// detail screen. When the screen is already mounted, the router skips the
  /// push: the screen reacts to new entries via `ref.watch` on its feature's
  /// queue notifier, so a second push would only stack duplicate screens.
  ///
  /// Detail-route events use [_navGuardPayloadKeys] for entity-id matching;
  /// list-route events bypass that mechanism entirely.
  ///
  /// Currently empty: `jobNewRequest` previously lived here as a list-route
  /// because the technician's offers screen was a router-pushed full-screen.
  /// The screen has since been replaced by `IncomingJobSheetHost` (a global
  /// queue-state-driven overlay), so the list-route plumbing is no longer
  /// needed for that event. The mechanism is kept for any future event type
  /// that targets a list-style screen (batched chat history, e.g.).
  static const _listRouteEvents = <SystemEventType>{};

  // ─── Entry point ───────────────────────────────────────────────────────

  void handleEvent(
    SystemEventEntity event,
    TargetRole currentUserRole,
    WidgetRef ref,
  ) {
    // 1. Role gate — the backend occasionally fans out to the wrong role
    //    during B2B account sharing; drop silently.
    if (event.targetRole != currentUserRole) {
      return;
    }

    // 2. Unknown gate — an event type the client doesn't know about cannot
    //    be routed safely; drop.
    if (event.eventType == SystemEventType.unknown) {
      return;
    }

    // 3. Urgency dispatch.
    switch (event.urgency) {
      case EventUrgency.highUrgency:
        _handleHigh(event);
      case EventUrgency.lowUrgency:
        _handleLow(event);
      case EventUrgency.silent:
        break;
    }

    // 4. ACK — fire and forget, batched by the sync notifier.
    if (event.isCritical) {
      ref.read(eventSyncProvider.notifier).acknowledge(event.id);
    }
  }

  // ─── High-urgency: full-screen route push ──────────────────────────────

  void _handleHigh(SystemEventEntity event) {
    final route = _highUrgencyRoutes[event.eventType];
    if (route == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    if (_isAlreadyOnEntity(ctx, route, event)) return;

    GoRouter.of(ctx).push(route, extra: jsonEncode(event.payload));
  }

  bool _isAlreadyOnEntity(
    BuildContext ctx,
    String targetRoute,
    SystemEventEntity event,
  ) {
    // The orchestrator hands us `navigatorKey.currentContext` — that BuildContext
    // sits *above* the route-builder subtree, so `GoRouterState.of(ctx)` throws
    // ("There is no GoRouterState above the current context"). Read the current
    // URI from the GoRouter instance instead, which is available at any context
    // at or below the GoRouter widget.
    final currentUri =
        GoRouter.of(ctx).routerDelegate.currentConfiguration.uri;
    final currentLocation = currentUri.path;
    if (!currentLocation.startsWith(targetRoute)) return false;

    // List-route events: a single screen instance handles every entry, so
    // "already on the route" is sufficient — no per-entity discrimination.
    if (_listRouteEvents.contains(event.eventType)) return true;

    final key = _navGuardPayloadKeys[event.eventType];
    if (key == null) return false; // no guard defined — always push.

    final incomingId = event.payload[key]?.toString();
    if (incomingId == null) return false;

    // Match against path segments — works whether the screen reads the id
    // from the path (`/customer/job-accepted/42`) or query (`?job_id=42`).
    if (currentUri.pathSegments.contains(incomingId)) return true;
    if (currentUri.queryParameters[key] == incomingId) return true;
    return false;
  }

  // ─── Low-urgency: MaterialBanner ───────────────────────────────────────

  void _handleLow(SystemEventEntity event) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final icon = _bannerIcons[event.eventType] ?? Icons.notifications;
    final title = _bannerTitles[event.eventType] ?? 'Notification';
    final body = _bannerBody(event);

    final banner = MaterialBanner(
      leading: Icon(icon),
      content: Text(
        body == null ? title : '$title — $body',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            final tapRoute = _lowUrgencyTapRoutes[event.eventType];
            final ctx = navigatorKey.currentContext;
            if (tapRoute != null && ctx != null) {
              final resolved = _resolveLowUrgencyPath(tapRoute, event);
              GoRouter.of(ctx).push(resolved, extra: jsonEncode(event.payload));
            }
          },
          child: const Text('View'),
        ),
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('Dismiss'),
        ),
      ],
    );

    messenger.showMaterialBanner(banner);
    Timer(_bannerAutoDismiss, () {
      // guard against late dismiss after a newer banner replaced this one
      scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
    });
  }

  String? _bannerBody(SystemEventEntity event) {
    final p = event.payload;
    switch (event.eventType) {
      case SystemEventType.chatMessage:
        return p['sender_name']?.toString();
      case SystemEventType.techEnRoute:
      case SystemEventType.techArrived:
        return p['technician_name']?.toString();
      case SystemEventType.paymentReceived:
        final amount = p['amount']?.toString();
        return amount != null ? 'PKR $amount' : null;
      case SystemEventType.walletLowBalance:
        final balance = p['balance']?.toString();
        return balance != null ? 'Balance: PKR $balance' : null;
      case SystemEventType.bookingRejected:
        // `reason` discriminator is sent by both the technician-decline arm
        // (`technician_declined`) and the SLA-expiry arm (`sla_timeout`);
        // any other value falls through to a generic copy so a future
        // backend `reason` doesn't crash the surface.
        switch (p['reason']?.toString()) {
          case 'technician_declined':
            return 'Technician declined — tap to view.';
          case 'sla_timeout':
            return 'No technician responded in time — tap to view.';
          default:
            return 'Your booking is no longer available — tap to view.';
        }
      default:
        return null;
    }
  }

  /// Substitute the `:<payload-key>` token in [template] with the
  /// stringified payload value, when [event]'s type has an entry in
  /// [_lowUrgencyTapPayloadKeys] and the payload carries the key.
  ///
  /// Returns [template] unchanged when:
  ///   * the event type has no payload-key entry (existing static-path
  ///     low-urgency events), or
  ///   * the payload is missing the named key (defensive — push the raw
  ///     template so the failure is visible at the route layer rather
  ///     than masked by a silent home-screen fallback).
  String _resolveLowUrgencyPath(String template, SystemEventEntity event) {
    final key = _lowUrgencyTapPayloadKeys[event.eventType];
    if (key == null) return template;
    final value = event.payload[key]?.toString();
    if (value == null) return template;
    return template.replaceFirst(':$key', value);
  }
}
