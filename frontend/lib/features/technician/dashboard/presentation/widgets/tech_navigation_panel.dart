import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/widgets/map/job_location_map.dart';
import '../../../../orchestrator/domain/entities/booking_ui_block.dart';
import '../../../../orchestrator/presentation/providers/booking_action_executor.dart';
import '../../../../orchestrator/presentation/providers/booking_detail_provider.dart';

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

    // Flip first, navigate second. If the status flip fails we still
    // launch Maps — the tech is en route physically whether or not the
    // server knows yet, and the backend's en_route is idempotent for a
    // future retry. We just notify the tech via snack so they know
    // the customer wasn't pinged.
    if (action != null && bookingId != null && !_flipping) {
      setState(() => _flipping = true);
      try {
        await ref.read(bookingActionExecutorProvider).execute(action);
        // Refresh the orchestrator's detail cache so the local tab
        // updates immediately. The mirrored broadcast (B1) will also
        // arrive via WS shortly; this is the local-fast path.
        ref.invalidate(bookingDetailProvider(bookingId));
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
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Fall through to the snack.
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Could not open Maps on this device.')),
      );
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
