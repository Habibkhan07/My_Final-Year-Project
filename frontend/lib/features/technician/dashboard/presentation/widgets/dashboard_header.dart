import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Single-row Stitch layout:
///   [avatar] [Hi, {firstName}]   ······   [Online pill] [Wallet: Rs. X pill]
///
/// Greeting is sourced from the auth cache (firstName persisted in shared
/// prefs at signup), not from the dashboard payload — see DASHBOARD_FEATURE.md
/// for the rationale.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.dashboard,
    required this.isToggleLoading,
    required this.onToggle,
  });

  final TechnicianDashboardEntity dashboard;
  final bool isToggleLoading;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(
      authProvider.select((async) => async.value?.user?.firstName),
    );

    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _Avatar(profilePicture: dashboard.profilePicture),
          const SizedBox(width: 12),
          Expanded(child: _Greeting(firstName: firstName)),
          const SizedBox(width: 8),
          _OnlineToggle(
            isOnline: dashboard.isOnline,
            isLoading: isToggleLoading,
            onToggle: (next) {
              HapticFeedback.mediumImpact();
              onToggle(next);
            },
          ),
          const SizedBox(width: 8),
          _WalletPill(balance: dashboard.walletBalance),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.profilePicture});
  final String? profilePicture;

  @override
  Widget build(BuildContext context) {
    if (profilePicture == null) return const _AvatarFallback();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: profilePicture!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _AvatarPlaceholder(),
        errorWidget: (_, _, _) => const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryFixed,
      child: Icon(Icons.person_outline, color: AppColors.primaryContainer, size: 22),
    );
  }
}

/// Solid-colour placeholder shown while a real avatar image is loading.
/// Distinct from [_AvatarFallback] (used on null URL or load failure) so a
/// successful-but-still-loading image doesn't briefly flash the person icon.
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryFixed,
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.firstName});
  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final name = (firstName == null || firstName!.isEmpty) ? 'there' : firstName!;
    return Text(
      'Hi, $name',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Pill-shaped Online/Offline toggle.
///
/// When online, the indicator dot pulses (Stitch's animate-pulse) to draw
/// the eye to the live state. When loading, the dot is replaced by a spinner.
class _OnlineToggle extends StatefulWidget {
  const _OnlineToggle({
    required this.isOnline,
    required this.isLoading,
    required this.onToggle,
  });

  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

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
    return GestureDetector(
      onTap: widget.isLoading ? null : () => widget.onToggle(!widget.isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isOnline
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicator(),
            const SizedBox(width: 6),
            Text(
              widget.isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: widget.isOnline
                    ? AppColors.onSecondaryFixed
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicator() {
    if (widget.isLoading) {
      return SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: widget.isOnline ? AppColors.secondary : AppColors.outline,
        ),
      );
    }
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isOnline ? AppColors.secondary : AppColors.outline,
      ),
    );
    if (!widget.isOnline) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulse),
      child: dot,
    );
  }
}

/// Wallet pill — "Wallet: Rs. 1,500" matching Stitch.
///
/// Tappable: opens a placeholder snackbar today, will route to the JazzCash
/// top-up flow once that feature lands. Tapping is the affordance that
/// answers "what is this Rs?" — the Stitch label inline already hints, the
/// tap will open a sheet explaining the platform commission.
class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Wallet & top-up details coming soon.'),
            ),
          );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        ),
        child: Text(
          'Wallet: Rs. ${balance.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
