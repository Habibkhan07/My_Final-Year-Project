import 'dart:async';
import 'dart:convert';
import 'dart:developer';

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
  static const _logName = 'core.presentation.urgency_router';

  const EventUrgencyRouter({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  // ─── Route tables ──────────────────────────────────────────────────────

  static const _highUrgencyRoutes = <SystemEventType, String>{
    SystemEventType.jobDispatched: '/technician/incoming-job',
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
  };

  static const _bannerIcons = <SystemEventType, IconData>{
    SystemEventType.chatMessage: Icons.chat_bubble,
    SystemEventType.techEnRoute: Icons.location_on,
    SystemEventType.techArrived: Icons.location_on,
    SystemEventType.paymentReceived: Icons.account_balance_wallet,
    SystemEventType.walletLowBalance: Icons.account_balance_wallet_outlined,
  };

  static const _bannerTitles = <SystemEventType, String>{
    SystemEventType.chatMessage: 'New Message',
    SystemEventType.techEnRoute: 'Technician On The Way',
    SystemEventType.techArrived: 'Technician Arrived',
    SystemEventType.paymentReceived: 'Payment Received',
    SystemEventType.walletLowBalance: 'Low Wallet Balance',
  };

  /// Per-event-type payload key used to detect "already viewing this exact
  /// entity" for the nav guard. Types not in the map skip the guard and
  /// always push — the guard is an optimization, not a correctness gate.
  static const _navGuardPayloadKeys = <SystemEventType, String>{
    SystemEventType.jobDispatched: 'job_id',
    SystemEventType.jobAccepted: 'job_id',
    SystemEventType.quoteGenerated: 'quote_id',
    SystemEventType.quoteApproved: 'quote_id',
    SystemEventType.jobCompleted: 'job_id',
    SystemEventType.disputeOpened: 'dispute_id',
    SystemEventType.disputeResolved: 'dispute_id',
  };

  // ─── Entry point ───────────────────────────────────────────────────────

  void handleEvent(
    SystemEventEntity event,
    TargetRole currentUserRole,
    WidgetRef ref,
  ) {
    // 1. Role gate — the backend occasionally fans out to the wrong role
    //    during B2B account sharing; drop silently.
    if (event.targetRole != currentUserRole) {
      log(
        'dropping event id=${event.id} for role=${event.targetRole.name} '
        '(current=${currentUserRole.name})',
        name: _logName,
      );
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
    if (ctx == null) {
      log('no navigator context — skipping push for ${event.id}',
          name: _logName);
      return;
    }

    if (_isAlreadyOnEntity(ctx, route, event)) {
      log('already on $route for the same entity; skipping push',
          name: _logName);
      return;
    }

    GoRouter.of(ctx).push(route, extra: jsonEncode(event.payload));
  }

  bool _isAlreadyOnEntity(
    BuildContext ctx,
    String targetRoute,
    SystemEventEntity event,
  ) {
    final currentLocation = GoRouterState.of(ctx).matchedLocation;
    if (!currentLocation.startsWith(targetRoute)) return false;

    final key = _navGuardPayloadKeys[event.eventType];
    if (key == null) return false; // no guard defined — always push.

    final incomingId = event.payload[key]?.toString();
    if (incomingId == null) return false;

    // Match against path segments — works whether the screen reads the id
    // from the path (`/customer/job-accepted/42`) or query (`?job_id=42`).
    final currentUri = GoRouterState.of(ctx).uri;
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
              GoRouter.of(ctx).push(tapRoute, extra: jsonEncode(event.payload));
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
      default:
        return null;
    }
  }
}
