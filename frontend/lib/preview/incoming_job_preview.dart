// DEV-ONLY preview entry for the IncomingJobSheetHost.
//
// Run on a device or desktop:
//   flutter run -t lib/preview/incoming_job_preview.dart -d chrome
//   flutter run -t lib/preview/incoming_job_preview.dart -d linux
//   flutter run -t lib/preview/incoming_job_preview.dart -d <android-device-id>
//
// What you see:
//   * A faux-dashboard "canvas" so the scrim has something to darken behind
//     the sheet.
//   * Seed buttons that inject offers into IncomingJobQueueNotifier through
//     the preview-only `debugSeedRequest` method. The global IncomingJobSheetHost
//     is mounted via `MaterialApp.builder`, so the sheet animates in on the
//     first seed and reacts to subsequent seeds the same way a live
//     `job_new_request` event would.
//
// Serialized one-offer model:
//   The host now shows ONE offer at a time. Seeding two requests causes the
//   most-urgent to display; the second is queued in memory and would only
//   surface if the first resolved (accept / decline) — a useful demo for the
//   head-sticky priority behavior once the swipe widget lands.
//
// Why a separate entry point:
//   * No auth, no Firebase init, no WebSocket, no Riverpod overrides for the
//     realtime stack. Just the sheet host + its dependencies.
//   * Lets the design be reviewed in seconds instead of standing up the full
//     backend → WS → mapper pipeline.
//
// Important: this file imports `debugSeedRequest`, which is preview-only on
// the queue notifier. Do not copy that call into production code.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_spacing.dart';
import '../features/technician/incoming_job_requests/domain/entities/booking_type.dart';
import '../features/technician/incoming_job_requests/domain/entities/job_new_request.dart';
import '../features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import '../features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart';

void main() {
  runApp(const ProviderScope(child: _PreviewApp()));
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Incoming Job — Preview Lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _PreviewHome(),
      // Mounts the same sheet host the production app uses. The host watches
      // incomingJobQueueProvider and surfaces the sheet over whatever route
      // the navigator is currently showing.
      builder: (context, child) {
        return IncomingJobSheetHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _PreviewHome extends ConsumerWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueLen =
        ref.watch(incomingJobQueueProvider.select((s) => s.queue.length));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text(
          'Incoming Job — Preview Lab',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DashboardCanvas(),
            const SizedBox(height: 20),
            const _SectionHeading('SEED OFFERS'),
            const SizedBox(height: 10),
            _SeedButton(
              label: 'Inspection — Rs. 500, ASAP',
              subtitle: 'Customer wants someone right now (tight 5-min SLA)',
              accent: AppColors.error,
              onTap: () => _seed(ref, _inspectionAsap()),
            ),
            const SizedBox(height: 8),
            _SeedButton(
              label: 'Fixed Price — Rs. 1,800, Today afternoon',
              subtitle: 'Scheduled job — eyebrow reads "Today · 4:30 PM"',
              accent: const Color(0xFFD97706),
              onTap: () => _seed(ref, _fixedScheduledToday()),
            ),
            const SizedBox(height: 8),
            _SeedButton(
              label: 'Labor — Rs. 3,200, Tomorrow morning',
              subtitle: 'Eyebrow reads "Tomorrow · 9:00 AM" (no locality)',
              accent: AppColors.secondary,
              onTap: () => _seed(ref, _laborScheduledTomorrow()),
            ),
            const SizedBox(height: 18),
            _SeedButton(
              label: 'Seed two offers (head-sticky demo)',
              subtitle: 'Most-urgent shows; second queues until head resolves',
              accent: AppColors.primaryContainer,
              onTap: () {
                _seed(ref, _inspectionAsap());
                _seed(ref, _fixedScheduledToday());
              },
            ),
            const SizedBox(height: 18),
            _SeedButton(
              label: 'Reset queue',
              subtitle: 'Clears the sheet (slide-down + scrim fade-out)',
              accent: AppColors.outline,
              onTap: () => _resetAll(ref),
              filled: false,
            ),
            const SizedBox(height: 24),
            _StatusLine(queueLen: queueLen),
            const SizedBox(height: 12),
            const _Tips(),
          ],
        ),
      ),
    );
  }

  void _seed(WidgetRef ref, JobNewRequest request) {
    ref.read(incomingJobQueueProvider.notifier).debugSeedRequest(request);
  }

  void _resetAll(WidgetRef ref) {
    final notifier = ref.read(incomingJobQueueProvider.notifier);
    final ids = ref
        .read(incomingJobQueueProvider)
        .queue
        .map((j) => j.jobId)
        .toList();
    for (final id in ids) {
      notifier.removeRequest(id);
    }
  }
}

// ─── Sample request builders ───────────────────────────────────────────────
//
// All fixtures use slaWindow >= 5 minutes — the floor the backend will enforce
// per flag.md (commit 2 obligation). A seed with a sub-5-min slaWindow would
// be unrealistic and would produce a too-fast drain on the swipe widget.

JobNewRequest _inspectionAsap() {
  // ASAP detection in the eyebrow is `scheduledStart - now <= 30min`. Setting
  // scheduledStart very close to now → eyebrow reads "ASAP".
  final now = DateTime.now();
  return JobNewRequest(
    jobId: 9001,
    serviceName: 'Plumbing Inspection',
    bookingType: BookingType.inspection,
    payoutRupees: 500,
    payoutContext: 'Inspection visit — quote built on-site',
    scheduledStart: now.add(const Duration(minutes: 5)),
    expiresAt: now.add(const Duration(minutes: 5)),
    slaWindow: const Duration(minutes: 5),
    locationLabel: 'Gulberg, Lahore',
  );
}

JobNewRequest _fixedScheduledToday() {
  // Today at 4:30 PM (or tomorrow at 4:30 PM if it's already past 4:30 PM)
  // → eyebrow reads "Today · 4:30 PM" or "Tomorrow · 4:30 PM" accordingly.
  final now = DateTime.now();
  final today430 = DateTime(now.year, now.month, now.day, 16, 30);
  return JobNewRequest(
    jobId: 9002,
    serviceName: 'Ceiling Fan Installation',
    bookingType: BookingType.fixedGig,
    payoutRupees: 1800,
    payoutContext: 'Fixed price set by platform — no quoting required',
    scheduledStart: today430.isAfter(now.add(const Duration(minutes: 30)))
        ? today430
        : today430.add(const Duration(days: 1)),
    expiresAt: now.add(const Duration(minutes: 5)),
    slaWindow: const Duration(minutes: 5),
    locationLabel: 'F-7, Islamabad',
  );
}

JobNewRequest _laborScheduledTomorrow() {
  // `locationLabel` deliberately left null on this fixture so the preview
  // demonstrates the legacy / null-locality fallback (address row hidden,
  // no placeholder).
  final now = DateTime.now();
  final tomorrow900 = DateTime(now.year, now.month, now.day + 1, 9, 0);
  return JobNewRequest(
    jobId: 9003,
    serviceName: 'Daily Wage Helper',
    bookingType: BookingType.laborGig,
    payoutRupees: 3200,
    payoutContext: 'Hourly labor — mark complete on-site',
    scheduledStart: tomorrow900,
    expiresAt: now.add(const Duration(minutes: 5)),
    slaWindow: const Duration(minutes: 5),
    locationLabel: null,
  );
}

// ─── Page chrome ───────────────────────────────────────────────────────────

class _DashboardCanvas extends StatelessWidget {
  const _DashboardCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.handyman,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Technician',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'You are online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT • 2:15 PM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'AC Repair — DHA Phase 5',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This panel is a stand-in for the real technician dashboard. '
            'When you seed an offer, the bottom sheet slides up over this '
            'canvas with a 40% scrim. Drag the sheet down past 30% to lift '
            'the scrim and peek at this canvas — the sheet snaps back when '
            'released.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.outline,
      ),
    );
  }
}

class _SeedButton extends StatelessWidget {
  const _SeedButton({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.filled = true,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppShapes.radiusMD),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          border: Border.all(
            color: filled
                ? accent.withValues(alpha: 0.45)
                : AppColors.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppShapes.radiusFull),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.queueLen});
  final int queueLen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShapes.radiusSM),
      ),
      child: Row(
        children: [
          Icon(
            queueLen == 0 ? Icons.hourglass_empty : Icons.queue,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            queueLen == 0
                ? 'Queue is empty — sheet is hidden.'
                : queueLen == 1
                    ? 'Queue has 1 offer.'
                    : 'Queue has $queueLen offers (only the head is shown).',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    const lines = [
      'Seed one offer → the sheet slides up at the single fixed snap and '
          'shows the four-block card with the swipe-to-accept pill.',
      'Watch the colored fill recede from the right as the SLA elapses. '
          'Green > 50%, amber 20–50%, red < 20%. The thumb shifts color to '
          'match the band.',
      'Drag the thumb right past ~80% of the colored runway → onAccept '
          'fires, the thumb morphs to a check, and the offer leaves the '
          'queue. Release short of 80% → the thumb springs back.',
      'Let the colored fill fully drain → onExpire fires automatically and '
          'the offer leaves the queue (no swipe required).',
      'Tap Decline → the offer leaves the queue. Decline stays a tap '
          '(reversible action); accept is a swipe (commitment).',
      'Drag the sheet down past 30% → the scrim lifts and the dashboard '
          'becomes visible. Release: the sheet snaps back to the snap.',
      'Tap the scrim → does nothing. A stray tap must not dismiss a '
          'high-payout offer.',
      'Seed two offers → only the head shows. The second is queued; head-'
          'sticky priority means a more-urgent newcomer does NOT swap with '
          'the visible card mid-decision.',
      'Tap "Reset queue" → the sheet slides out and the scrim fades.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('THINGS TO TRY'),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 4, color: AppColors.outline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
