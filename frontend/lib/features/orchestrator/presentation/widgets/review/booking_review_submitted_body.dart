import 'package:flutter/material.dart';

import '../../../domain/entities/review.dart';
import '../_palette/orchestrator_palette.dart';

/// Read-only recap rendered after the customer has submitted their
/// review. Replaces the form so a second submit is impossible from
/// the UI (the backend also enforces via the OneToOne — this is the
/// UX-side reinforcement).
class BookingReviewSubmittedBody extends StatelessWidget {
  const BookingReviewSubmittedBody({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OrchestratorPalette.brandPrimaryTint06,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: OrchestratorPalette.brandPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Thanks for your review',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: OrchestratorPalette.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Star recap.
          Row(
            children: List.generate(5, (i) {
              final filled = i < review.rating;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 24,
                  color: OrchestratorPalette.brandPrimary,
                ),
              );
            }),
          ),

          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.tags
                  .map((tagKey) => _TagPill(label: _humanise(tagKey)))
                  .toList(),
            ),
          ],

          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '"${review.text}"',
              style: const TextStyle(
                color: OrchestratorPalette.inkSecondary,
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fallback humaniser for tag keys when the recap is rendered cold
  /// (without the predefined-tag dictionary in hand). Converts
  /// `quality_work` → `Quality work`. Good enough — the recap is
  /// post-submit; the customer already saw the proper labels on the
  /// form.
  String _humanise(String key) {
    if (key.isEmpty) return key;
    final words = key.split('_');
    return words.map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: OrchestratorPalette.brandPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
