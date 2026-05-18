import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    show NotificationPermission;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/widgets/map/job_location_map.dart';
import '../../../../orchestrator/domain/entities/booking_ui_block.dart';
import '../../../../orchestrator/presentation/providers/booking_action_executor.dart';
import '../../../../orchestrator/presentation/providers/booking_detail_provider.dart';
import '../../../location_broadcaster/presentation/providers/dependency_injection.dart';

/// Single source of truth for the technician's "I'm leaving for the
/// customer now" affordance.
///
/// Tap Start Navigation = two effects, atomic from the tech's POV:
///   1. POST `/api/bookings/<id>/en-route/` so the backend flips
///      CONFIRMED → EN_ROUTE and notifies the customer ("Technician is
///      on the way").
///   2. Hand off to external Google Maps for turn-by-turn.
///
/// Rendered on two surfaces (with identical behaviour):
///   * the dashboard's up-next card
///   * the orchestrator's CONFIRMED body, when this booking IS the
///     dashboard's up-next
///
/// The orchestrator's `PrimaryActionSlot` suppresses its own
/// "I'm on my way" button on tech+CONFIRMED+up-next so the verb isn't
/// duplicated.
///
/// Web-safe: `canLaunchUrl` may return true on Chrome but the OS may
/// have no handler for `tel:` or `https:` (uncommon for https). Both
/// paths surface a snack instead of failing silently.
class TechNavigationPanel extends ConsumerStatefulWidget {
  const TechNavigationPanel({
    super.key,
    required this.destLat,
    required this.destLng,
    this.customerPhone,
    this.bookingId,
    this.flipAction,
    this.mapHeight = 200,
  });

  final double destLat;
  final double destLng;
  final String? customerPhone;

  /// When provided, tapping Start Navigation also POSTs `/en-route/` to
  /// flip the booking status. Null in tests or for surfaces that should
  /// only launch Maps without changing state.
  final int? bookingId;

  /// Server-emitted `BookingUiAction` to fire on tap (preferred over
  /// hardcoding the `/en-route/` path). The orchestrator caller passes
  /// `booking.ui.primaryAction` so the wire contract stays server-
  /// driven. The dashboard up-next caller can't (no BookingDetail in
  /// scope on that screen) so it leaves this null and the panel falls
  /// back to constructing the action locally from [bookingId].
  /// When the orchestrator's primaryAction is suppressed by the
  /// PrimaryActionSlot for up-next-CONFIRMED, the parent should pass
  /// the suppressed action through here.
  final BookingUiAction? flipAction;

  final double mapHeight;

  @override
  ConsumerState<TechNavigationPanel> createState() =>
      _TechNavigationPanelState();
}

class _TechNavigationPanelState extends ConsumerState<TechNavigationPanel> {
  // setState-tracked so the button's busy spinner rebuilds. A plain
  // `bool` field would block the re-entry POST but leave the button
  // visually enabled — the tech could spam-tap and open multiple Maps
  // intents thinking nothing happened. Wrapping in setState gives the
  // user immediate feedback the action is in flight.
  bool _flipping = false;

  Future<void> _onStartNavigation() async {
    final messenger = ScaffoldMessenger.of(context);
    final bookingId = widget.bookingId;

    // Prefer the server-emitted BookingUiAction (passed by the
    // orchestrator caller) so the endpoint, method, and label all
    // come from `orchestrator_ui.py`. Dashboard up-next callers don't
    // have a BookingDetail in scope, so we fall back to constructing
    // the action locally from bookingId — same wire path, but with
    // the inherent risk that a future backend rename of `/en-route/`
    // would silently break this call site. Both branches are gated
    // on bookingId != null + !_flipping.
    final action = widget.flipAction ??
        (bookingId == null
            ? null
            : BookingUiAction(
                label: 'Start Navigation',
                endpoint: '/bookings/$bookingId/en-route/',
                method: 'POST',
              ));

    // Order matters here — this method has to thread three things
    // (status flip, Maps handoff, foreground GPS service) without any
    // pair racing on Android's foreground/task arbitration. The
    // sequence that actually works:
    //
    //   1. Pre-warm location + notification permissions while the
    //      activity is visible. Any system dialog fires here, not
    //      behind Maps. The controller's _ensurePermissions later
    //      finds everything granted and runs without UI.
    //
    //   2. POST /en-route/. The backend flips status and broadcasts
    //      "tech is on the way" to the customer immediately — so the
    //      customer ping is dispatched before the tech disappears
    //      into Maps. Errors snack; we still launch Maps because
    //      "the tech is en route physically whether the server knows
    //      or not" and /en-route/ is idempotent for retry.
    //
    //   3. launchUrl(Maps). Maps takes the foreground here, while we
    //      have NOT yet invalidated bookingDetailProvider — the
    //      orchestrator's foreground location controller is still on
    //      CONFIRMED, so its _startService hasn't been triggered.
    //      This avoids the FGS startup (isolate spawn + notification
    //      post) racing with Maps for foreground, which on this
    //      Android build prevents Maps from claiming focus.
    //
    //   4. ref.invalidate(bookingDetailProvider). Now that our app
    //      is in the background and Maps owns the foreground, the
    //      refetch resolves with EN_ROUTE, the controller's listener
    //      fires, and the platform FGS starts silently in the
    //      background. Permissions are already granted (step 1), so
    //      no UI can pull the activity back.
    if (action != null && bookingId != null && !_flipping) {
      setState(() => _flipping = true);
      try {
        await _prewarmTrackingPermissions();
        await ref.read(bookingActionExecutorProvider).execute(action);
      } on HttpFailure catch (e) {
        // 400 ERROR_INVALID_TRANSITION = "already EN_ROUTE or later" —
        // benign, the tech is just opening Maps again on the same job.
        // Anything else → surface to the tech.
        if (e.code != 'invalid_transition') {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('Could not notify customer: ${e.message}')),
            );
        }
      } catch (_) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                "Couldn't tell the customer you're on the way — but Maps will still open.",
              ),
            ),
          );
      } finally {
        if (mounted) setState(() => _flipping = false);
      }
    }

    // Always launch Maps — even on a flip failure, the tech wants nav.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.destLat},${widget.destLng}'
      '&travelmode=driving',
    );
    var mapsOpened = false;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        mapsOpened = true;
      }
    } catch (_) {
      // Fall through to the snack below.
    }

    // Trigger the FGS only AFTER Maps owns the foreground. Skipped on
    // launch failure — there's no reason to start GPS broadcasting if
    // the tech isn't actually heading out, and the standard WS sync
    // on the next app resume will catch the screen up to whatever the
    // server already recorded from step 2.
    if (mapsOpened && bookingId != null) {
      ref.invalidate(bookingDetailProvider(bookingId));
    }

    if (!mapsOpened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open Maps on this device.')),
        );
    }
  }

  /// Mirrors `ForegroundLocationServiceController._ensurePermissions`
  /// just enough to force any system dialog to appear here (activity in
  /// foreground) rather than after the Maps handoff. Idempotent when
  /// permissions are already granted — `requestPermission` /
  /// `requestNotificationPermission` no-op without showing a dialog.
  /// All errors are swallowed: this is best-effort UX, the controller's
  /// own _ensurePermissions remains the authoritative gate.
  Future<void> _prewarmTrackingPermissions() async {
    try {
      final geo = ref.read(geolocatorBackendProvider);
      var permission = await geo.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await geo.requestPermission();
      }

      final fg = ref.read(foregroundTaskBackendProvider);
      final notif = await fg.checkNotificationPermission();
      if (notif != NotificationPermission.granted) {
        await fg.requestNotificationPermission();
      }

      // Best-effort upgrade to background location (matches the
      // controller). Android 10 prompts; Android 11+ no-ops because
      // the upgrade can only be granted via Settings.
      if (permission == LocationPermission.whileInUse) {
        await geo.requestPermission();
      }
    } catch (_) {
      // Controller's _ensurePermissions handles the final outcome.
    }
  }

  Future<void> _onCall() async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = widget.customerPhone;
    if (phone == null || phone.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Customer phone unavailable.')),
        );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {
      // Fall through to the snack.
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Calls are not supported on this device.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final phoneAvailable =
        widget.customerPhone != null && widget.customerPhone!.isNotEmpty;
    return Column(
      children: [
        JobLocationMap(
          lat: widget.destLat,
          lng: widget.destLng,
          height: widget.mapHeight,
          borderRadius: BorderRadius.circular(AppShapes.radiusSM),
        ),
        const SizedBox(height: 12),
        _StartNavigationButton(onTap: _onStartNavigation, busy: _flipping),
        const SizedBox(height: 8),
        _CallCustomerButton(onTap: _onCall, enabled: phoneAvailable),
      ],
    );
  }
}

class _StartNavigationButton extends StatelessWidget {
  const _StartNavigationButton({required this.onTap, this.busy = false});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Block re-entry while a flip is in flight. The tap target stays
      // visually present (just non-responsive) so the tech sees the
      // spinner explanation rather than a button that disappears.
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: busy ? 0.75 : 1.0,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(AppShapes.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Start Navigation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CallCustomerButton extends StatelessWidget {
  const _CallCustomerButton({required this.onTap, required this.enabled});
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppShapes.radiusXL),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_outlined, size: 16, color: AppColors.onSurface),
              SizedBox(width: 6),
              Text(
                'Contact Customer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
