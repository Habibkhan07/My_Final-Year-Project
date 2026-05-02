import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/job_new_request.dart';
import 'incoming_job_card.dart';

/// Body of the incoming-job bottom sheet.
///
/// **Serialized one-offer model.** The host's queue is a head-sticky priority
/// queue (most-urgent at index 0; once promoted to the head, an offer cannot be
/// displaced until it resolves). The sheet renders ONLY the head — the tech
/// never sees a peek strip, a "+N pending" pill, or an "ALSO PENDING" list.
/// The earlier multi-offer surfaces (deck / peek bar / queue list) were
/// removed because asking a low-literacy user to decode an abstract count or
/// a stack of layered cards failed in field testing — the deck and the +N pill
/// both required interpretation rather than reaction.
///
/// What this widget owns:
///   * The outer surface chrome — surface color, rounded top corners, top
///     shadow — so the design tokens stay in one place.
///   * The empty-queue safe path. The host slides the sheet out on the
///     non-empty → empty transition; during the slide-out frame the queue
///     can momentarily be empty while the sheet is still mounted, which would
///     otherwise crash on `queue.first`.
///
/// What the host owns:
///   * the queue (via Riverpod, head-sticky priority order)
///   * the snap controller (locked to a single fraction)
///   * accept / decline handlers
class IncomingJobSheet extends StatelessWidget {
  const IncomingJobSheet({
    super.key,
    required this.scrollController,
    required this.queue,
    required this.onAccept,
    required this.onDecline,
    required this.onExpire,
  });

  /// The DraggableScrollableSheet's scroll controller. Threaded into the
  /// scrollable so drags above the snap top scroll the body instead of
  /// fighting the sheet.
  final ScrollController scrollController;

  /// Live queue. Order is head-sticky priority (head = `queue.first`).
  final List<JobNewRequest> queue;

  /// Fired once when the technician completes the swipe-to-accept gesture
  /// on the head card.
  final VoidCallback onAccept;

  /// Fired when Decline is tapped on the head card.
  final VoidCallback onDecline;

  /// Fired once when the head card's drain reaches zero (SLA elapsed and
  /// the technician didn't act in time).
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final Widget body = queue.isEmpty
        ? const SizedBox.shrink()
        : ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              IncomingJobCard(
                request: queue.first,
                onAccept: onAccept,
                onDecline: onDecline,
                onExpire: onExpire,
              ),
            ],
          );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppShapes.radiusXL - 4), // 24
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}
