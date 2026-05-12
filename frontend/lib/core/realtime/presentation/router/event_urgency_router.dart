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
    SystemEventType.customerArriving: '/booking/:job_id',
    // chatMessage / paymentReceived / walletLowBalance are deliberately
    // ABSENT — the chat + wallet features are unshipped placeholders
    // (`_ComingSoonScreen` in app_router.dart) and routing a user there
    // is a dead-end at best, a confusing mis-tap at worst. The banners
    // still surface (informational), but their View button is hidden
    // when no route exists. When the chat / wallet features land,
    // restore the entries here and the View button reappears.
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
    SystemEventType.customerArriving: Icons.directions_walk,
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
    SystemEventType.customerArriving: 'Customer is coming out',
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
  /// entity". Used by both:
  ///
  ///   * **High-urgency push guard** — when an event would push a route the
  ///     user is already on, skip the duplicate push.
  ///   * **Low-urgency banner suppression** — when a banner is about a
  ///     booking the user is currently viewing, skip the banner; the
  ///     booking-detail screen's own `BookingOrchestratorEventsNotifier`
  ///     invalidates the detail provider silently, so the screen refreshes
  ///     without an interruptive banner about the booking the user is
  ///     literally looking at.
  ///
  /// Types not in the map skip the guard and always push / always banner —
  /// the guard is an optimization, not a correctness gate.
  ///
  /// Most entries use `'job_id'` because the orchestrator screen URL
  /// template is `/booking/:job_id`. Quote / dispute ids are not in the URL,
  /// so guarding by quote_id / dispute_id would always misfire and double-push.
  ///
  /// For `bookingRescheduled` the guard key is `child_booking_id` — once
  /// the user is on the child screen (auto-redirected by the in-app
  /// `bookingRescheduledNotifier` OR routed there by an earlier tap), a
  /// stale banner tap shouldn't push a duplicate of the same screen.
  ///
  /// `chatMessage`, `paymentReceived`, `walletLowBalance` are deliberately
  /// absent — those banners are valid even when on the booking-detail
  /// screen because they target a different screen entirely.
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
    // Low-urgency booking events — these all surface as banners that
    // would otherwise interrupt a user already on the booking screen.
    SystemEventType.techEnRoute: 'job_id',
    SystemEventType.techArrived: 'job_id',
    SystemEventType.customerArriving: 'job_id',
    SystemEventType.jobAccepted: 'job_id',
    SystemEventType.bookingRejected: 'job_id',
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
    // The orchestrator hands us `navigatorKey.currentContext` — that
    // BuildContext sits *above* the route-builder subtree, so
    // `GoRouterState.of(ctx)` throws ("There is no GoRouterState above the
    // current context"). Read the current URI from the GoRouter instance
    // instead, which is available at any context at or below the
    // GoRouter widget.
    //
    // We use `.state.uri` (the topmost route's URI) rather than
    // `.routerDelegate.currentConfiguration.uri` because the latter
    // returns the *initial* URI of the route match list — for a
    // `push('/booking/42')` on top of `/start`, `currentConfiguration.uri`
    // still reports `/start`, while `.state.uri` correctly reports
    // `/booking/42`. (Verified against go_router 17.1.0 source.)
    final currentUri = GoRouter.of(ctx).state.uri;
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

    // Suppress the banner when the user is already viewing the entity
    // the event is about. The booking-detail screen's
    // `BookingOrchestratorEventsNotifier` invalidates the detail
    // provider for the same event, so the user sees the new state
    // appear in-place (with the thin top progress bar) instead of a
    // banner saying "your tech is on the way" *about the booking they're
    // staring at*. Banners for events targeting other screens
    // (chatMessage / paymentReceived / walletLowBalance) still fire —
    // those entries are absent from `_navGuardPayloadKeys`.
    final tapRoute = _lowUrgencyTapRoutes[event.eventType];
    final ctx = navigatorKey.currentContext;
    if (tapRoute != null &&
        ctx != null &&
        _isAlreadyOnEntity(ctx, tapRoute, event)) {
      return;
    }

    final icon = _bannerIcons[event.eventType] ?? Icons.notifications;
    final title = _bannerTitles[event.eventType] ?? 'Notification';
    final body = _bannerBody(event);

    // Hide the "View" action when the event type has no tap-route — its
    // feature is unshipped (chat / wallet placeholders) or otherwise has
    // nowhere meaningful to land. Without this guard, a tap would push a
    // dead "Coming soon" route the user can't escape via the back button
    // without losing their place. The Dismiss button is always present so
    // the banner is never inescapable.
    final routeToPush = tapRoute; // local non-null capture for closure

    final banner = MaterialBanner(
      leading: Icon(icon),
      content: Text(
        body == null ? title : '$title — $body',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (routeToPush != null)
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              final ctx = navigatorKey.currentContext;
              if (ctx != null) {
                final resolved = _resolveTemplatedPath(routeToPush, event);
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
      case SystemEventType.customerArriving:
        return 'They\'re walking out to meet you.';
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
