import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/technician_status.dart';
import '../../domain/failures/tech_status_failure.dart';
import '../providers/technician_status_provider.dart';

/// Single status-screen shown to a tech who has applied but isn't APPROVED
/// yet. Replaces the prior split between RegistrationSuccessScreen (the
/// "you just submitted" landing) and the older PendingApprovalScreen (the
/// "come back later" view) — both `/technician/success` and
/// `/technician/pending` route here now.
///
/// Renders variants by reading [technicianStatusProvider] directly:
///   * `AsyncLoading` → slim skeleton.
///   * `AsyncError`   → minimal "couldn't reach server" + Try-again.
///   * `Pending`      → brand-blue hero. No CTA — the RefreshIndicator
///                      on the parent owns the refresh affordance via
///                      pull-to-refresh; a redundant button would just
///                      add noise.
///   * `Rejected`     → red hero + compact reason card + Re-apply CTA.
///   * `Approved` / `NoProfile` → loading shim (the router redirect will
///                                bounce them out on the next frame).
///
/// Exit affordance: the AppBar back arrow exits to ``/home`` (the
/// customer surface) via ``context.go`` — a hard nav rather than a pop
/// since this screen can be the root after onboarding finalize, with
/// no underlying stack to peel back.
class PendingApprovalScreen extends ConsumerWidget {
  /// True when the screen was reached straight from a successful
  /// onboarding finalize (router serves this view at /technician/success
  /// in that case). Drives the "Submitted just now ✓" banner so a fresh
  /// applicant gets emotional closure without re-introducing a separate
  /// success screen.
  final bool justSubmitted;

  const PendingApprovalScreen({super.key, this.justSubmitted = false});

  static const _brand = Color(0xFF0051AE);
  static const _bg = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(technicianStatusProvider);

    return Scaffold(
      backgroundColor: _bg,
      // Slim top bar with a single back affordance that exits to the
      // customer home. The screen is reachable both as the holding view
      // after an admin re-routes a PENDING tech here AND as the
      // post-submit landing from the wizard, so a hard ``context.go``
      // is correct: there may be no underlying route stack to peel.
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: const Color(0xFF151C24),
          onPressed: () => context.go('/home'),
          tooltip: 'Back to Karigar',
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _brand,
          // Bug fix (audit #2): the previous implementation swallowed
          // refresh errors via ``.catchError((_) => NoProfile)``, which
          // left the screen stuck on a loading shim with no error UI.
          // Now: invalidate, wait for the new fetch, and let any
          // exception propagate so the AsyncError branch of
          // ``statusAsync.when`` renders the error body.
          onRefresh: () async {
            ref.invalidate(technicianStatusProvider);
            await ref.read(technicianStatusProvider.future);
          },
          child: statusAsync.when(
            data: (status) => _StatusBody(
              status: status,
              justSubmitted: justSubmitted,
            ),
            loading: () => const _LoadingBody(),
            error: (err, _) => _ErrorBody(failure: err),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status variants
// ---------------------------------------------------------------------------

class _StatusBody extends StatelessWidget {
  final TechnicianStatus status;
  final bool justSubmitted;
  const _StatusBody({required this.status, required this.justSubmitted});

  @override
  Widget build(BuildContext context) {
    // APPROVED / NoProfile arrive here only during the brief frame between
    // the status resolving and the router redirect firing. Show the slim
    // skeleton so the user never sees stale copy.
    final isTransient = status is TechnicianStatusApproved ||
        status is TechnicianStatusNoProfile;
    if (isTransient) return const _LoadingBody();

    final isRejected = status is TechnicianStatusRejected;
    final reason = status is TechnicianStatusRejected
        ? (status as TechnicianStatusRejected).reason
        : null;

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (justSubmitted && !isRejected) ...[
            const SizedBox(height: 8),
            const _JustSubmittedBanner(),
          ],
          const SizedBox(height: 32),
          _Hero(isRejected: isRejected),
          const SizedBox(height: 24),
          _Headline(text: isRejected ? 'Not approved' : 'Under review'),
          const SizedBox(height: 8),
          _Subtitle(
            text: isRejected
                ? 'Submit again to try once more.'
                : 'Usually approved within 1–2 days.',
          ),
          const SizedBox(height: 20),
          _StatusPill(isRejected: isRejected),
          if (isRejected && reason != null && reason.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _ReasonCard(reason: reason),
          ],
          const Spacer(),
          // Pending: no button — the RefreshIndicator on the parent
          // owns the refresh affordance via swipe-down. Rejected keeps
          // the re-apply CTA because it routes to a different surface
          // (the wizard) which pull-to-refresh cannot reach.
          if (isRejected)
            _PrimaryButton(
              label: 'Submit a new application',
              icon: Icons.refresh,
              // push (not go) so the rejected screen stays in the stack
              // and the wizard's back arrow on step 0 returns here. With
              // ``go`` the wizard becomes the new stack root and back is
              // a dead-end. From the wizard's back arrow → here → AppBar
              // back → /home, which matches the user's exit expectations.
              onPressed: () => context.push('/technician/onboarding'),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Brand-blue pill rendered above the hero when the user just submitted.
/// Closes the emotional loop without re-introducing a second screen.
class _JustSubmittedBanner extends StatelessWidget {
  const _JustSubmittedBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PendingApprovalScreen._brand.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle,
              size: 16,
              color: PendingApprovalScreen._brand,
            ),
            SizedBox(width: 8),
            Text(
              'Application sent',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: PendingApprovalScreen._brand,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: const Center(
        child: CircularProgressIndicator(
          color: PendingApprovalScreen._brand,
        ),
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
    return "We couldn't reach the server.";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Shell(
      child: Column(
        children: [
          const SizedBox(height: 64),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: PendingApprovalScreen._brand,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const _Headline(text: 'Connection problem'),
          const SizedBox(height: 8),
          _Subtitle(text: _message()),
          const Spacer(),
          _PrimaryButton(
            label: 'Try again',
            icon: Icons.refresh,
            onPressed: () => ref.invalidate(technicianStatusProvider),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// Pull-to-refresh requires a scrollable child; LayoutBuilder pins the
/// content to a min-height of the viewport so pulls always register.
class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              height: constraints.maxHeight - 24,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool isRejected;
  const _Hero({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final color = isRejected
        ? const Color(0xFFE11D48)
        : PendingApprovalScreen._brand;
    final tint = isRejected
        ? const Color(0xFFFFE4E6)
        : const Color(0xFFEFF4FB);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isRejected ? Icons.close_rounded : Icons.hourglass_top_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String text;
  const _Headline({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Color(0xFF151C24),
        height: 1.2,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final String text;
  const _Subtitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6B7280),
        height: 1.45,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isRejected;
  const _StatusPill({required this.isRejected});

  @override
  Widget build(BuildContext context) {
    final color = isRejected
        ? const Color(0xFFE11D48)
        : PendingApprovalScreen._brand;
    final tint = isRejected
        ? const Color(0xFFFFE4E6)
        : const Color(0xFFEFF4FB);
    final label = isRejected ? 'Rejected' : 'Pending';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final String reason;
  const _ReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFE11D48),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF151C24),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PendingApprovalScreen._brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: const Color(0x660051AE),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}

