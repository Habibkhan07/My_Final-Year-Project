import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../domain/entities/system_event_type.dart';

/// Visual tone for an in-app event banner. Drives both the left accent stripe
/// and the icon-container tint. Resolved to a concrete [Color] via
/// [_accentColor]; the tint background is derived as a 12% wash of that
/// color (Material 3 tonal-surface convention).
///
/// The mapping from [SystemEventType] to [EventAccent] lives in
/// [_eventAccents] below — co-located so adding a new banner-eligible event
/// is a single-file edit.
enum EventAccent { info, success, warning, critical }

const Map<SystemEventType, EventAccent> _eventAccents = {
  SystemEventType.chatMessage: EventAccent.info,
  SystemEventType.techEnRoute: EventAccent.info,
  SystemEventType.techArrived: EventAccent.success,
  SystemEventType.customerArriving: EventAccent.info,
  SystemEventType.paymentReceived: EventAccent.success,
  SystemEventType.walletLowBalance: EventAccent.warning,
  SystemEventType.jobAccepted: EventAccent.success,
  SystemEventType.bookingRejected: EventAccent.critical,
  SystemEventType.quoteRevisionRequested: EventAccent.info,
  SystemEventType.quoteDeclined: EventAccent.warning,
  SystemEventType.bookingCancelled: EventAccent.critical,
  SystemEventType.bookingNoShow: EventAccent.warning,
  SystemEventType.bookingRescheduled: EventAccent.info,
};

Color _accentColor(EventAccent accent) {
  switch (accent) {
    case EventAccent.info:
      return AppColors.primary;
    case EventAccent.success:
      return AppColors.secondary;
    case EventAccent.warning:
      return const Color(0xFFE6810D);
    case EventAccent.critical:
      return AppColors.error;
  }
}

/// Imperative entry point used by [EventUrgencyRouter] to surface a low-
/// urgency in-app banner. Returns a disposer the router schedules a 5s
/// timer against — auto-dismiss behaviour is unchanged from the previous
/// `MaterialBanner`-based implementation.
///
/// `onView` is null when no tap-route exists for the event (chat/wallet
/// placeholders) — the trailing chevron is hidden but the rest of the
/// banner is still tappable as a no-op. The dismiss "✕" is always shown so
/// the banner is never inescapable.
///
/// Why an [OverlayEntry] and not `MaterialBanner`: `MaterialBanner` enforces
/// its own internal padding, divider, and full-width layout that can't be
/// styled into a floating card. Owning the overlay lets us control margin,
/// shadow, animation, and hit-targets without fighting Material defaults.
///
/// [overlay] MUST be the root navigator's [OverlayState] — typically
/// `navigatorKey.currentState!.overlay`. We accept it explicitly (rather
/// than calling `Overlay.of(context)`) because the router's
/// `navigatorKey.currentContext` is the Navigator widget's own context,
/// which sits ABOVE the Navigator-owned Overlay in the tree. `Overlay.of`
/// from there walks UP looking for an ancestor Overlay, finds none, and
/// throws — the silent failure that previously made the banner never
/// appear despite the rest of the pipeline being healthy.
VoidCallback showEventBanner({
  required OverlayState overlay,
  required SystemEventType eventType,
  required IconData icon,
  required String title,
  required String? body,
  required VoidCallback? onView,
}) {
  final accent = _eventAccents[eventType] ?? EventAccent.info;
  final accentColor = _accentColor(accent);

  late OverlayEntry entry;
  final controller = _BannerController();

  entry = OverlayEntry(
    builder: (_) => _EventBannerOverlay(
      controller: controller,
      accentColor: accentColor,
      icon: icon,
      title: title,
      body: body,
      onView: onView == null
          ? null
          : () {
              controller.dismiss();
              onView();
            },
      onDismiss: controller.dismiss,
      onFullyDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );

  overlay.insert(entry);
  return controller.dismiss;
}

/// Lightweight bridge that lets the imperative `showEventBanner` caller and
/// the stateful overlay widget share a single dismiss intent. The overlay
/// owns the animation; the caller (or the router's auto-dismiss timer) just
/// fires intent.
class _BannerController {
  VoidCallback? _onDismiss;
  bool _dismissed = false;

  void attach(VoidCallback onDismiss) => _onDismiss = onDismiss;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _onDismiss?.call();
  }
}

class _EventBannerOverlay extends StatefulWidget {
  final _BannerController controller;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String? body;
  final VoidCallback? onView;
  final VoidCallback onDismiss;
  final VoidCallback onFullyDismissed;

  const _EventBannerOverlay({
    required this.controller,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.body,
    required this.onView,
    required this.onDismiss,
    required this.onFullyDismissed,
  });

  @override
  State<_EventBannerOverlay> createState() => _EventBannerOverlayState();
}

class _EventBannerOverlayState extends State<_EventBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    widget.controller.attach(_animateOut);
    _anim.forward();
  }

  Future<void> _animateOut() async {
    if (!mounted) return;
    await _anim.reverse();
    if (!mounted) return;
    widget.onFullyDismissed();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.accentColor.withValues(alpha: 0.12);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Material(
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                color: AppColors.surfaceContainerLowest,
                child: InkWell(
                  onTap: widget.onView,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: widget.accentColor),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 12, 8, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: tint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: 22,
                                    color: widget.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.body != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.body!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color:
                                                AppColors.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (widget.onView != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _CloseButton(onTap: widget.onDismiss),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const SizedBox(
        width: 40,
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: AppColors.outline,
        ),
      ),
    );
  }
}
