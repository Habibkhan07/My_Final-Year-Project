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
  //
  // Orchestrator-relevant high-urgency events all converge on the single
  // `/booking/:job_id` orchestrator screen (sprint v1, session 3 — closes
  // flag #26). The screen adapts its body to the booking's status, so a
  // single route absorbs `quote_generated`, `quote_approved`, `job_completed`,
  // `dispute_opened`, and `dispute_resolved`. Path templating below.
  static const _highUrgencyRoutes = <SystemEventType, String>{
    SystemEventType.quoteGenerated: '/booking/:job_id',
    SystemEventType.quoteApproved: '/booking/:job_id',
    SystemEventType.jobCompleted: '/booking/:job_id',
    SystemEventType.disputeOpened: '/booking/:job_id',
    SystemEventType.disputeResolved: '/booking/:job_id',
  };

  static const _lowUrgencyTapRoutes = <SystemEventType, String>{
    SystemEventType.techEnRoute: '/booking/:job_id',
    SystemEventType.techArrived: '/booking/:job_id',
    SystemEventType.chatMessage: '/shared/chat',
    SystemEventType.paymentReceived: '/shared/wallet',
    SystemEventType.walletLowBalance: '/shared/wallet',
    SystemEventType.jobAccepted: '/booking/:job_id',
    SystemEventType.bookingRejected: '/booking/:job_id',
    // Booking-orchestrator v1 informational events (session 3). Tap surfaces
    // the orchestrator screen; in-app `bookingRescheduledNotifier` rewrites
    // to the child booking when the customer is currently on the original.
    SystemEventType.quoteRevisionRequested: '/booking/:job_id',
    SystemEventType.quoteDeclined: '/booking/:job_id',
    SystemEventType.bookingCancelled: '/booking/:job_id',
    SystemEventType.bookingNoShow: '/booking/:job_id',
    // Rescheduled tap goes DIRECTLY to the child booking. The original is
    // cancelled and not actionable; navigating there leaves the user
    // stranded (the in-app `bookingRescheduledNotifier` covers the case
    // where the user is already on the original screen, but it can't
    // help banner-tap or FCM-cold-launch — `ref.listen` doesn't replay
    // the current value at subscription time, so a deep-link mounting
    // the screen AFTER the event arrived would never trigger redirect).
    SystemEventType.bookingRescheduled: '/booking/:child_booking_id',
  };

  static const _bannerIcons = <SystemEventType, IconData>{
    SystemEventType.chatMessage: Icons.chat_bubble,
    SystemEventType.techEnRoute: Icons.location_on,
    SystemEventType.techArrived: Icons.location_on,
    SystemEventType.paymentReceived: Icons.account_balance_wallet,
    SystemEventType.walletLowBalance: Icons.account_balance_wallet_outlined,
    SystemEventType.jobAccepted: Icons.event_available,
    SystemEventType.bookingRejected: Icons.event_busy,
    SystemEventType.quoteRevisionRequested: Icons.edit_note,
    SystemEventType.quoteDeclined: Icons.cancel_outlined,
    SystemEventType.bookingCancelled: Icons.event_busy,
    SystemEventType.bookingNoShow: Icons.person_off_outlined,
    SystemEventType.bookingRescheduled: Icons.schedule,
  };

  static const _bannerTitles = <SystemEventType, String>{
    SystemEventType.chatMessage: 'New Message',
    SystemEventType.techEnRoute: 'Technician On The Way',
    SystemEventType.techArrived: 'Technician Arrived',
    SystemEventType.paymentReceived: 'Payment Received',
    SystemEventType.walletLowBalance: 'Low Wallet Balance',
    SystemEventType.jobAccepted: 'Booking confirmed',
    SystemEventType.bookingRejected: 'Booking unavailable',
    SystemEventType.quoteRevisionRequested: 'Customer wants to bargain',
    SystemEventType.quoteDeclined: 'Quote declined',
    SystemEventType.bookingCancelled: 'Booking cancelled',
    SystemEventType.bookingNoShow: 'No-show reported',
    SystemEventType.bookingRescheduled: 'Booking rescheduled',
  };

  /// Per-event-type payload key used to detect "already viewing this exact
  /// entity" for the nav guard. Types not in the map skip the guard and
  /// always push — the guard is an optimization, not a correctness gate.
  ///
  /// Every entry below uses `'job_id'` because the orchestrator screen URL
  /// template is `/booking/:job_id`. Quote / dispute ids are not in the URL,
  /// so guarding by quote_id / dispute_id would always misfire and double-push.
  ///
  /// For `bookingRescheduled` the guard key is `child_booking_id` — once
  /// the user is on the child screen (auto-redirected by the in-app
  /// `bookingRescheduledNotifier` OR routed there by an earlier tap), a
  /// stale banner tap shouldn't push a duplicate of the same screen.
  static const _navGuardPayloadKeys = <SystemEventType, String>{
    SystemEventType.quoteGenerated: 'job_id',
    SystemEventType.quoteApproved: 'job_id',
    SystemEventType.jobCompleted: 'job_id',
    SystemEventType.disputeOpened: 'job_id',
    SystemEventType.disputeResolved: 'job_id',
    SystemEventType.quoteRevisionRequested: 'job_id',
    SystemEventType.quoteDeclined: 'job_id',
    SystemEventType.bookingCancelled: 'job_id',
    SystemEventType.bookingNoShow: 'job_id',
    SystemEventType.bookingRescheduled: 'child_booking_id',
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
    final template = _highUrgencyRoutes[event.eventType];
    if (template == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final resolved = _resolveTemplatedPath(template, event);
    if (resolved == null) return; // missing required payload key — skip push.

    if (_isAlreadyOnEntity(ctx, template, event)) return;

    GoRouter.of(ctx).push(resolved, extra: jsonEncode(event.payload));
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

    // For templated routes (`/booking/:job_id`), match against the static
    // prefix only — the dynamic segment is compared via the nav-guard key
    // below. `startsWith('/booking/:job_id')` would never match a real URL.
    final templatePrefix = _staticPrefix(targetRoute);
    if (!currentLocation.startsWith(templatePrefix)) return false;

    // List-route events: a single screen instance handles every entry, so
    // "already on the route" is sufficient — no per-entity discrimination.
    if (_listRouteEvents.contains(event.eventType)) return true;

    final key = _navGuardPayloadKeys[event.eventType];
    if (key == null) return false; // no guard defined — always push.

    final incomingId = event.payload[key]?.toString();
    if (incomingId == null) return false;

    // Match against path segments — works whether the screen reads the id
    // from the path (`/booking/42`) or query (`?job_id=42`).
    if (currentUri.pathSegments.contains(incomingId)) return true;
    if (currentUri.queryParameters[key] == incomingId) return true;
    return false;
  }

  /// Strip everything from the first `:` token onward so prefix-startsWith
  /// checks work for templated routes. `'/booking/:job_id'` → `'/booking/'`.
  static String _staticPrefix(String template) {
    final tokenStart = template.indexOf(':');
    if (tokenStart == -1) return template;
    return template.substring(0, tokenStart);
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
              final resolved = _resolveTemplatedPath(tapRoute, event);
              if (resolved == null) return; // missing payload key — skip.
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
      case SystemEventType.jobAccepted:
        // `technician_display_name` is the customer-facing string built
        // server-side from `user.get_full_name()` (BOOKINGS_API.md §1.3).
        // Defensively fall through when missing — replayed pre-flag-#25
        // EventLog rows are not expected (this surface ships in lockstep
        // with the registry change), but keeping the fallback symmetrical
        // with the other banner-body cases costs nothing.
        final tech = p['technician_display_name']?.toString();
        return tech != null
            ? '$tech is on the way — tap to view.'
            : 'Your technician is on the way — tap to view.';
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
      case SystemEventType.quoteRevisionRequested:
        return 'Customer is asking to revise the quote — tap to view.';
      case SystemEventType.quoteDeclined:
        return 'Customer declined the quote — tap to view.';
      case SystemEventType.bookingCancelled:
        // Backend filters delivery so the actor doesn't get notified of
        // their own cancel; the recipient is always the *other* side. We
        // discriminate copy by `targetRole` so the customer sees "your
        // technician cancelled" and the technician sees "the customer
        // cancelled" — generic "this booking was cancelled" reads as
        // self-blame to whichever side didn't initiate.
        return event.targetRole == TargetRole.customer
            ? 'Your technician cancelled — tap to view.'
            : 'The customer cancelled — tap to view.';
      case SystemEventType.bookingNoShow:
        // `actor` discriminates which side failed to show; recipient is
        // always the non-actor (backend filters). Phrase the copy from the
        // recipient's perspective.
        final actor = p['actor']?.toString();
        if (actor == 'customer' && event.targetRole == TargetRole.technician) {
          return 'Customer did not show — tap to view.';
        }
        if (actor == 'tech' && event.targetRole == TargetRole.customer) {
          return 'Your technician did not show — tap to view.';
        }
        return 'Marked as a no-show — tap to view.';
      case SystemEventType.bookingRescheduled:
        return 'Rescheduled — tap to open the new booking.';
      default:
        return null;
    }
  }

  /// Generic `:<token>` substitution. The orchestrator screen path template
  /// `/booking/:job_id` resolves to `/booking/42` when the event payload
  /// carries `'job_id': 42`. Works for any path template by reading the
  /// token name directly from the URL — no per-event-type key map needed.
  ///
  /// Returns `null` (rather than the unresolved template) when a required
  /// token is missing from the payload. Callers skip the navigation —
  /// pushing the raw `:job_id` literal would crash GoRouter, and pushing
  /// the wrong screen silently is worse than a no-op.
  String? _resolveTemplatedPath(String template, SystemEventEntity event) {
    if (!template.contains(':')) return template;
    final regex = RegExp(r':(\w+)');
    String resolved = template;
    for (final match in regex.allMatches(template)) {
      final key = match.group(1)!;
      final value = event.payload[key]?.toString();
      if (value == null) return null; // visible failure: skip the push.
      resolved = resolved.replaceFirst(':$key', value);
    }
    return resolved;
  }
}
