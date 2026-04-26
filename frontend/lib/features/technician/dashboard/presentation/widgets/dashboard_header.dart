import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/technician_dashboard_entity.dart';

/// Purely presentational — owns no state.
/// The screen passes [isToggleLoading] and [onToggle] so the toggle widget
/// is disabled during the optimistic update without this widget knowing why.
class DashboardHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(profilePicture: dashboard.profilePicture),
              const SizedBox(width: 12),
              const Expanded(child: _AppTitle()),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                color: AppColors.onSurfaceVariant,
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OnlineToggle(
                isOnline: dashboard.isOnline,
                isLoading: isToggleLoading,
                onToggle: onToggle,
              ),
              const Spacer(),
              _WalletBadge(balance: dashboard.walletBalance),
            ],
          ),
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
    if (profilePicture != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(profilePicture!),
      );
    }
    return const CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryFixed,
      child: Icon(Icons.person_outline, color: AppColors.primaryContainer, size: 24),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIELD_OPS v1.0',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.primaryContainer,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Technician Dashboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({
    required this.isOnline,
    required this.isLoading,
    required this.onToggle,
  });

  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => onToggle(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicator(isOnline, isLoading),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                key: ValueKey(isOnline),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.onSecondaryFixed : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicator(bool isOnline, bool isLoading) {
    if (isLoading) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOnline ? AppColors.secondary : AppColors.outline,
        ),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.secondary : AppColors.outline,
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppShapes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 16,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Rs. ${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
