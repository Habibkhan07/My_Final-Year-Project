import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/technician_status.dart';
import '../../domain/failures/tech_status_failure.dart';
import '../providers/technician_status_provider.dart';

/// Holding screen for technicians whose application is either still
/// pending admin review or was rejected. Owns its own state by watching
/// [technicianStatusProvider] directly — the router routes to this screen
/// for PENDING / REJECTED *and* for the still-loading / error states.
///
/// Variants rendered:
/// * `AsyncLoading` → centred spinner.
/// * `AsyncError` → "couldn't reach server" + retry button.
/// * `TechnicianStatusPending` → amber hourglass + "under review" copy.
/// * `TechnicianStatusRejected` → red cancel icon + reason block.
/// * `TechnicianStatusApproved` / `TechnicianStatusNoProfile` → blank
///   transition state — the router redirect will pop the user out on
///   the next frame, so we briefly show a spinner to avoid a flash of
///   misleading "rejected" or "pending" copy.
///
/// Refresh paths:
/// * Pull-to-refresh on the scroll view.
/// * "Check again" text button — same effect, for platforms (web/desktop)
///   where pull-to-refresh isn't discoverable.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  static const Color _brandBlue = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(technicianStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(technicianStatusProvider);
            // Wait for the new fetch to land so the spinner stays on
            // screen long enough to feel responsive. `future` resolves
            // once the new fetch completes (success or error).
            await ref.read(technicianStatusProvider.future).catchError(
              (_) => const TechnicianStatusNoProfile(),
            );
          },
          child: statusAsync.when(
            data: (status) => _StatusBody(status: status),
            loading: () => const _LoadingBody(),
            error: (err, _) => _ErrorBody(failure: err),
          ),
        ),
      ),
    );
  }
}

// --- Body variants -----------------------------------------------------------

class _StatusBody extends ConsumerWidget {
  final TechnicianStatus status;
  const _StatusBody({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRejected = status is TechnicianStatusRejected;
    final reason = status is TechnicianStatusRejected
        ? (status as TechnicianStatusRejected).reason
        : null;
    // APPROVED / NoProfile arrive here only during the brief frame
    // between the status resolving and the router redirect firing.
    // Show a spinner so the user never sees stale pending/rejected copy.
    final isTransient = status is TechnicianStatusApproved ||
        status is TechnicianStatusNoProfile;

    if (isTransient) {
      return const _LoadingBody();
    }

    return _Scaffolded(
      child: Column(
        children: [
          const SizedBox(height: 48),
          _StatusIcon(isRejected: isRejected),
          const SizedBox(height: 32),
          Text(
            isRejected
                ? 'Application Not Approved'
                : 'Application Under Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isRejected
                ? "We weren't able to approve your application at this time."
                : "Thanks for applying. Our team is reviewing your documents — we'll let you know as soon as you're approved.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
          if (isRejected && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ReasonBlock(reason: reason),
          ],
          const SizedBox(height: 32),
          _ContactSupportNote(isRejected: isRejected),
          const SizedBox(height: 48),
          if (isRejected) ...[
            // Re-apply CTA: the backend service resets the existing
            // REJECTED row in place when finalize is hit again, so the
            // user keeps their profile id + history. The router redirect
            // explicitly allows REJECTED users through /technician/onboarding.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PendingApprovalScreen._brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go('/technician/onboarding'),
                child: const Text(
                  'Submit a new application',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CheckAgainLink(onTap: () {
              ref.invalidate(technicianStatusProvider);
            }),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
          ] else ...[
            _CheckAgainLink(onTap: () {
              ref.invalidate(technicianStatusProvider);
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PendingApprovalScreen._brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return _Scaffolded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 200),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            'Checking your application status…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends ConsumerWidget {
  final Object failure;
  const _ErrorBody({required this.failure});

  String _message() {
    if (failure is TechStatusNetworkFailure) {
      return "You're offline. Check your connection and try again.";
    }
    if (failure is TechStatusUnauthorized) {
      return 'Your session expired. Please log in again.';
    }
    return "We couldn't reach the server. Please try again.";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Scaffolded(
      child: Column(
        children: [
          const SizedBox(height: 64),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: Colors.grey.shade600,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connection problem',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _message(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PendingApprovalScreen._brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ref.invalidate(technicianStatusProvider),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

// --- Shared bits -------------------------------------------------------------

/// Wraps body content in a vertically-scrollable column so
/// [RefreshIndicator] always has something to pull on, even when the
/// content fits the screen.
class _Scaffolded extends StatelessWidget {
  final Widget child;
  const _Scaffolded({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool isRejected;
  const _StatusIcon({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final color = isRejected ? Colors.red.shade600 : Colors.amber.shade700;
    final bg = isRejected ? Colors.red.shade50 : Colors.amber.shade50;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(
        isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
        color: color,
        size: 72,
      ),
    );
  }
}

class _ReasonBlock extends StatelessWidget {
  final String reason;
  const _ReasonBlock({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportNote extends StatelessWidget {
  final bool isRejected;
  const _ContactSupportNote({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    return Text(
      isRejected
          ? 'If you believe this was a mistake, please contact support.'
          : 'Most applications are reviewed within 1–2 business days.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _CheckAgainLink extends StatelessWidget {
  final VoidCallback onTap;
  const _CheckAgainLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Check status again'),
    );
  }
}
