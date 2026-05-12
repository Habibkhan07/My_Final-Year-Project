import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../customer/bookings/domain/entities/booking_ui_tone.dart';
import '../../../technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/tech_gps_frame.dart';
import '../../domain/entities/booking_orchestrator_role.dart';
import '../providers/booking_detail_provider.dart';
import '../providers/booking_orchestrator_events_notifier.dart';
import '../providers/booking_rescheduled_notifier.dart';
import '../providers/technician_location_stream_notifier.dart';
import '../providers/tracking_subscription_controller.dart';
import '../widgets/_palette/orchestrator_palette.dart';
import '../widgets/orchestrator_action_bar.dart';
import '../widgets/orchestrator_error_card.dart';
import '../widgets/orchestrator_hero_header.dart';
import '../widgets/orchestrator_skeleton.dart';
import '../widgets/sheets/help_sheet.dart';
import '../widgets/slots/body_slot.dart';
import '../widgets/slots/booking_summary_card.dart';
import '../widgets/slots/timeline_slot.dart';

/// The full-screen orchestrator. One screen, every status, two roles.
///
/// **Slot layout (top → bottom).**
///   1. [OrchestratorHeroHeader] — curved tone-tinted hero with back,
///      title, status pill (live-status pulse), dynamic subtitle, help.
///   2. [TimelineSlot] — phase progression dots with per-phase
///      timestamps.
///   3. [BodySlot] — exhaustive switch on status, hosted inside a
///      pull-to-refresh scroll view with a top fade under the curve.
///   4. [BookingSummaryCard] — service, scheduled slot, counterparty
///      with call CTA, address. Always rendered above the action bar
///      (hero/map leads, booking facts trail) — **except on
///      customer-side ARRIVED**, where it is suppressed here and
///      re-mounted at the scroll bottom of the body. Rationale: on
///      ARRIVED the customer's pinned [ArrivalActionCard] occupies the
///      action zone (description + countdown merged), and the summary
///      card moves into scroll-revealed territory so the call
///      affordance stays one scroll away without competing with the
///      "go outside" moment.
///   5. [OrchestratorActionBar] — lifted bottom surface hosting
///      [SecondaryActionsSlot] + [PrimaryActionSlot]. Surface bg + top
///      shadow visually separate the always-on action region from the
///      scrollable body.
///
/// **Ambient surface tint.** The Scaffold's background is tinted to the
/// status tone (warm amber for AWAITING, faint blue for EN_ROUTE, etc.)
/// at very low alpha — felt rather than seen, but lets each status feel
/// distinct without requiring the user to read the label.
///
/// **Refresh UX.**
///   * **Realtime** — `detailAsync.isRefreshing && detailAsync.hasValue`
///     renders a 3px brand-blue [LinearProgressIndicator] under the
///     header; data stays visible underneath; no spinner flash.
///   * **Manual** — pulling down on the body invalidates the detail
///     provider via [RefreshIndicator], giving users an escape hatch
///     when WS is flaky.
///
/// **Initial-load state.** Replaces a bare progress indicator with
/// [OrchestratorSkeleton] — shimmer matches the real layout, so users
/// see structure immediately.
///
/// **Error state.** Replaces inline `_ErrorBody` with
/// [OrchestratorErrorCard] — per-failure illustration, brand-blue
/// retry, optional "Contact support" tertiary action.
///
/// **Realtime wake-up.** `ref.watch` on the two screen-scoped notifiers
/// (events + rescheduled), the tech-gps stream notifier (handler must
/// register BEFORE subscribe_tracking goes upstream — see OSCREEN-1),
/// the subscription controller, and the foreground location service
/// controller. All five are `keepAlive: false`; `ref.read` would not
/// subscribe and they'd auto-dispose silently.
class BookingOrchestratorScreen extends ConsumerStatefulWidget {
  const BookingOrchestratorScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<BookingOrchestratorScreen> createState() =>
      _BookingOrchestratorScreenState();
}

class _BookingOrchestratorScreenState
    extends ConsumerState<BookingOrchestratorScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hysteresis-free threshold: header drops its shadow as soon as we
    // overscroll by 4px and adopts it back when content scrolls down.
    final scrolled = _scrollController.hasClients &&
        _scrollController.offset > 4;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  Future<void> _onPullToRefresh() async {
    // Manual escape hatch. Realtime + initial load go through
    // `bookingDetailProvider`'s own lifecycle; pulling down forces a
    // fresh fetch by invalidating it. Awaiting the future so the
    // indicator unspools when the new data arrives (or errors out).
    ref.invalidate(bookingDetailProvider(widget.jobId));
    try {
      await ref.read(bookingDetailProvider(widget.jobId).future);
    } catch (_) {
      // Errors are surfaced by the AsyncValue.when error branch.
      // Swallow here so RefreshIndicator dismisses cleanly.
    }
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: `ref.watch` on the five keepAlive: false notifiers so
    // they subscribe + survive the screen's lifetime. `ref.read` would
    // silently auto-dispose them. Order matters for OSCREEN-1: register
    // tech_gps handler BEFORE subscribe_tracking goes upstream.
    ref.watch(bookingOrchestratorEventsProvider(widget.jobId));
    ref.watch(bookingRescheduledProvider(widget.jobId));
    // `ref.listen` (not `ref.watch`) on the GPS frame stream so its
    // ~5s-cadence mutations don't rebuild the entire screen subtree.
    // Consumer widgets (EnRouteBodyStub, _CustomerArrivedBody) `watch`
    // it themselves to receive the marker position; the screen only
    // needs the keepAlive side-effect that comes from being listened.
    ref.listen<TechGpsFrame?>(
      technicianLocationStreamProvider(widget.jobId),
      (_, _) {},
    );
    ref.watch(trackingSubscriptionControllerProvider(widget.jobId));
    ref.watch(foregroundLocationServiceControllerProvider(widget.jobId));

    final detailAsync = ref.watch(bookingDetailProvider(widget.jobId));
    // Effective tone — AWAITING is remapped from `warning` (amber) to
    // `info` (faint blue) in the palette so the screen never flashes
    // yellow on first load.
    final tone = detailAsync.hasValue
        ? OrchestratorPalette.effectiveTone(detailAsync.requireValue)
        : BookingUiTone.neutral;
    final theme = Theme.of(context);

    return Scaffold(
      // Scaffold's own bg stays plain surface; the tint goes on an
      // AnimatedContainer one level down so tone shifts ease over
      // 320ms instead of cutting in one frame.
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        color: _ambientSurfaceTint(theme, tone),
        child: detailAsync.when(
          loading: () => const OrchestratorSkeleton(),
          error: (error, _) => Column(
            children: [
              _MinimalHeader(
                jobId: widget.jobId,
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: OrchestratorErrorCard(
                  failure: error,
                  onRetry: () =>
                      ref.invalidate(bookingDetailProvider(widget.jobId)),
                ),
              ),
            ],
          ),
          data: (booking) => _LoadedBody(
            booking: booking,
            isRefreshing: detailAsync.isRefreshing,
            isScrolled: _isScrolled,
            scrollController: _scrollController,
            onBack: () => Navigator.maybePop(context),
            onHelp: () => HelpSheet.show(context, booking: booking),
            onPullToRefresh: _onPullToRefresh,
          ),
        ),
      ),
    );
  }

  /// Faint tone-derived surface wash, sourced from the same
  /// [OrchestratorToneSpec] the hero header uses — so the page
  /// background and the hero are guaranteed to read as one toned
  /// surface family.
  ///
  /// **Why this routes through the palette.** The previous mapping
  /// reached for `colors.tertiaryContainer` / `colors.errorContainer`,
  /// which Material 3 auto-derives from a deep-blue seed as pink and
  /// coral. That leaked pink into the page background on AWAITING /
  /// CANCELLED screens. The palette's `toneSpec` ships brand-cool
  /// amber (warning) and burgundy red (negative) explicitly, bypassing
  /// M3's derivation entirely.
  static Color _ambientSurfaceTint(ThemeData theme, BookingUiTone tone) {
    final spec = OrchestratorPalette.toneSpec(tone, theme.colorScheme);
    // For neutral/unknown the palette returns plain surface — fine to
    // alphaBlend over surface (a no-op visually); keeping the same
    // code path simplifies the callsite.
    return Color.alphaBlend(spec.surfaceWash, theme.colorScheme.surface);
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.booking,
    required this.isRefreshing,
    required this.isScrolled,
    required this.scrollController,
    required this.onBack,
    required this.onHelp,
    required this.onPullToRefresh,
  });

  final BookingDetail booking;
  final bool isRefreshing;
  final bool isScrolled;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final Future<void> Function() onPullToRefresh;

  static const _brandBlue = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    // Two customer statuses move the summary card INTO the scrollable
    // body (re-mounted at the bottom by the body stub) so the action
    // zone is not interrupted by a tech-info card.
    //
    //   * ARRIVED — body is the live map; the pinned `ArrivalActionCard`
    //     in the action bar takes the "description + tap" focus. The
    //     customer is about to walk outside to meet the tech — the
    //     tech-info card has nothing to add to that moment.
    //
    //   * QUOTED — customer and technician are face-to-face post-
    //     arrival. The customer reviews the line items with the tech
    //     literally standing there; the action bar hosts Approve and
    //     (when labor is on the bill) "Negotiate price". Both actions
    //     are taken while looking at the quote next to the tech, so a
    //     tech-info card wedged between the quote and the action bar
    //     interrupts an in-person flow.
    //
    // Tech-side and informational statuses (CONFIRMED, INSPECTING,
    // IN_PROGRESS, terminal states) keep the always-on summary slot —
    // there's no in-person action moment to protect.
    final isCustomerView =
        booking.viewerRole == BookingOrchestratorRole.customer;
    final hideAlwaysOnSummary = isCustomerView &&
        (booking.status == BookingStatus.arrived ||
            booking.status == BookingStatus.quoted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrchestratorHeroHeader(
          booking: booking,
          onBack: onBack,
          onHelp: onHelp,
          isScrolled: isScrolled,
        ),
        // Thin 3px brand-blue progress bar during realtime-event refresh.
        // Always reserves 3px so the screen doesn't shift when it
        // toggles. The bar itself fades in/out via AnimatedSwitcher so
        // the appearance feels intentional, not a flash.
        SizedBox(
          height: 3,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isRefreshing
                ? const LinearProgressIndicator(
                    key: ValueKey('orchestrator-refresh-bar'),
                    minHeight: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_brandBlue),
                    backgroundColor: Color(0x140051AE),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        TimelineSlot(booking: booking),
        Expanded(
          child: RefreshIndicator(
            color: _brandBlue,
            displacement: 24,
            onRefresh: onPullToRefresh,
            // Soft top fade so scrolling body content gently dissolves
            // under the hero header instead of hard-cutting at its
            // edge. `dstIn` blend mode + a 4%-transparent → opaque
            // gradient produces a 24px alpha falloff at the top of the
            // viewport regardless of scroll offset (the mask is in
            // viewport-space, not content-space).
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black],
                stops: [0.0, 0.04, 1.0],
              ).createShader(rect),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                // AnimatedSwitcher keyed on status — when the WS event
                // flips the booking's status, the outgoing body
                // fades+slides up and the incoming body fades+slides
                // in (320ms). Map bodies have their own internal frame
                // tween, so the only swap-time animation comes from
                // this outer switcher.
                child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    ?currentChild,
                  ],
                ),
                  child: KeyedSubtree(
                    key: ValueKey(booking.status),
                    child: BodySlot(booking: booking),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!hideAlwaysOnSummary) BookingSummaryCard(booking: booking),
        OrchestratorActionBar(booking: booking),
      ],
    );
  }
}

/// Minimal header used during the error state — gives users a way back
/// out and identifies which booking failed to load, without depending on
/// a fully-loaded [BookingDetail]. Matches the hero header's neutral
/// palette so error pages feel cohesive with the rest of the screen.
///
/// Shows "Booking #N" so users (and the router test that pins
/// orchestrator-mounted via that string) can confirm which booking
/// errored.
class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.jobId, required this.onBack});

  final int jobId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: true,
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                'Booking #$jobId',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
