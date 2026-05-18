import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/widgets/map/map_provider.dart';
import '../../domain/failures/booking_detail_failure.dart';
import '_palette/orchestrator_palette.dart';

/// Per-failure illustrative error card.
///
/// **Replaces** the inline `_ErrorBody` that previously rendered a flat
/// error icon + Material `FilledButton`. The new surface is a centered
/// card with:
///   * a 72px tinted illustration circle (per-failure icon),
///   * a strong title + a softer body (existing copy preserved),
///   * a brand-blue [ElevatedButton] "Try again" — visual match for the
///     orchestrator's primary CTA language,
///   * a tertiary [TextButton] "Contact support" that opens `tel:` to
///     the configured `AppConstants.supportPhoneNumber` (gracefully
///     omitted when the constant is unset, e.g. in dev without
///     `--dart-define`).
///
/// Per-failure illustration mapping is intentionally Material-icon-only
/// — keeps the bundle slim and avoids a design-system commitment ahead
/// of the planned cleanup pass.
class OrchestratorErrorCard extends ConsumerWidget {
  const OrchestratorErrorCard({
    super.key,
    required this.failure,
    required this.onRetry,
    this.supportPhoneNumber = AppConstants.supportPhoneNumber,
  });

  final Object failure;
  final VoidCallback onRetry;

  /// Test seam — the default reads from the compile-time constant.
  /// Production calls leave this at the default; tests override.
  final String supportPhoneNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final illustration = _illustration(failure, theme);
    final (title, body) = _copy(failure);
    final canContactSupport = supportPhoneNumber.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: illustration.tint.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      illustration.icon,
                      size: 36,
                      color: illustration.tint,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OrchestratorPalette.brandPrimary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (canContactSupport) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _callSupport(context, ref),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text('Contact support'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callSupport(BuildContext context, WidgetRef ref) async {
    final launcher = ref.read(urlLauncherProvider);
    final uri = Uri(scheme: 'tel', path: supportPhoneNumber);
    final ok = await launcher.launch(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialler for $supportPhoneNumber'),
        ),
      );
    }
  }

  _Illustration _illustration(Object failure, ThemeData theme) {
    if (failure is BookingDetailNotFound) {
      return _Illustration(
        icon: Icons.search_off_rounded,
        tint: theme.colorScheme.tertiary,
      );
    }
    if (failure is BookingDetailNotParticipant) {
      return _Illustration(
        icon: Icons.lock_outline_rounded,
        tint: theme.colorScheme.error,
      );
    }
    if (failure is BookingDetailOfflineNoCache) {
      return _Illustration(
        icon: Icons.cloud_off_rounded,
        tint: theme.colorScheme.tertiary,
      );
    }
    if (failure is BookingDetailNetworkFailure) {
      return _Illustration(
        icon: Icons.wifi_off_rounded,
        tint: theme.colorScheme.tertiary,
      );
    }
    if (failure is BookingDetailServerFailure) {
      return _Illustration(
        icon: Icons.sentiment_dissatisfied_rounded,
        tint: theme.colorScheme.error,
      );
    }
    return _Illustration(
      icon: Icons.error_outline_rounded,
      tint: theme.colorScheme.error,
    );
  }

  (String, String) _copy(Object failure) {
    if (failure is BookingDetailNotFound) {
      return ('Not found', 'This booking does not exist.');
    }
    if (failure is BookingDetailNotParticipant) {
      return (
        'Not allowed',
        "You aren't a participant on this booking."
      );
    }
    if (failure is BookingDetailOfflineNoCache) {
      return (
        'You are offline',
        "We don't have a cached copy of this booking yet. Try again when you're online.",
      );
    }
    if (failure is BookingDetailNetworkFailure) {
      return ('Network error', 'Could not reach the server.');
    }
    if (failure is BookingDetailServerFailure) {
      return (
        'Something went wrong',
        'Our servers had a hiccup. Try again in a moment.',
      );
    }
    return ('Error', 'Something went wrong.');
  }
}

class _Illustration {
  const _Illustration({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;
}
