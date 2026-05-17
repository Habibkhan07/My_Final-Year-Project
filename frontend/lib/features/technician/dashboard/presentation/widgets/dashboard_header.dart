import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../technician/wallet/presentation/format.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Right-aligned status bar:
///   ··········   [● ONLINE]   [💳 Rs. X]
///
/// Wrapped in `SafeArea(top: true)` so the pills clear the system status bar
/// instead of colliding with it. Identity (avatar + greeting) was moved to
/// the Profile tab — the dashboard's job is to surface online/offline +
/// wallet state, not say hello.
///
/// Tap targets are sized to the Material 48dp guideline. Both pills use
/// `InkWell` for ripple feedback — the visual confirmation a tap was
/// received matters more here than for static UI because the tech is
/// often glancing at the phone in the field.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.dashboard,
    required this.isToggleLoading,
    required this.onToggle,
    this.isLocked = false,
  });

  final TechnicianDashboardEntity dashboard;
  final bool isToggleLoading;
  final ValueChanged<bool> onToggle;

  /// True when the tech's wallet is in lockout — disables the online
  /// toggle so the tech can't optimistically flip themselves back on
  /// (the backend would refuse anyway, see notifier's setOnline gate).
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.surfaceContainerLowest,
        // SafeArea already adds the status-bar inset on top, so we keep
        // our own top padding light (8dp) and give the bottom a bit more
        // (14dp) to separate the bar from the content below.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            const Spacer(),
            _OnlineToggle(
              isOnline: dashboard.isOnline,
              isLoading: isToggleLoading,
              isLocked: isLocked,
              onToggle: (next) {
                HapticFeedback.mediumImpact();
                onToggle(next);
              },
            ),
            const SizedBox(width: 12),
            _WalletPill(balance: dashboard.walletBalance),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped Online/Offline toggle.
///
/// When online, the indicator dot pulses (Stitch's animate-pulse) to draw
/// the eye to the live state. When loading, the dot is replaced by a spinner.
/// Sized to a 40dp tap target (Material spec is 48dp minimum, but the pill
/// is part of a status bar — the surrounding 8/14 padding lifts the
/// effective hit slop above the spec). `InkWell` ripple confirms the tap.
class _OnlineToggle extends StatefulWidget {
  const _OnlineToggle({
    required this.isOnline,
    required this.isLoading,
    required this.onToggle,
    this.isLocked = false,
  });

  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  /// Locked-out techs cannot tap the toggle. The pill renders dimmed
  /// and ignores taps; the [LockoutBanner] explains why.
  final bool isLocked;

  @override
  State<_OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends State<_OnlineToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Disable on loading OR lockout. Lockout takes precedence visually —
    // the pill renders dimmed (Opacity wrapper) so the tech reads "I
    // cannot use this", and the LockoutBanner alongside gives the why.
    final isDisabled = widget.isLoading || widget.isLocked;
    final bgColor = widget.isOnline
        ? AppColors.secondaryContainer
        : AppColors.surfaceContainerHigh;
    final fgColor = widget.isOnline
        ? AppColors.onSecondaryFixed
        : AppColors.onSurfaceVariant;

    // Animated decoration sits outside the Material so the BG colour
    // can transition between online/offline; Material(transparent) +
    // InkWell paints the ripple over it.
    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppShapes.radiusFull),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => widget.onToggle(!widget.isOnline),
          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _indicator(fgColor),
                const SizedBox(width: 8),
                Text(
                  widget.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return widget.isLocked ? Opacity(opacity: 0.5, child: pill) : pill;
  }

  Widget _indicator(Color color) {
    final activeColor = widget.isOnline ? AppColors.secondary : color;
    if (widget.isLoading) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          color: activeColor,
        ),
      );
    }
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activeColor,
      ),
    );
    if (!widget.isOnline) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulse),
      child: dot,
    );
  }
}

/// Wallet pill — "💳 Rs. 1,500" matching production fintech patterns.
///
/// Tappable: pushes the tech-only Wallet screen (`/wallet`) where the tech
/// sees their current balance plus Top up / Withdraw CTAs. The pill itself
/// stays current in real time via `WALLET_BALANCE_UPDATED` events patched
/// onto `TechnicianDashboardState.walletBalance` — see
/// `TechnicianDashboardNotifier.onWalletBalanceEvent`.
///
/// Icon + amount (no "Wallet:" prefix) is the standard fintech pill —
/// scans faster than text-only, and the destination route (`/wallet`)
/// makes the noun self-evident.
class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppShapes.radiusFull),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/wallet'),
        borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                formatRs(balance),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
