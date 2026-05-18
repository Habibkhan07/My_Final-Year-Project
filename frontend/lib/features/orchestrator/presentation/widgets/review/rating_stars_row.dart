import 'package:flutter/material.dart';

import '../_palette/orchestrator_palette.dart';

/// Five tappable stars with animated fill.
///
/// Stateless — visual state is owned by the parent's [ReviewFormState].
/// Tapping a star calls [onChanged] with the 1-based rating (1..5).
///
/// Visual: filled stars are amber-gold (`ratingGold`) — the universal
/// review-star convention. Empty stars use a faded brand-blue so the
/// row reads as part of the brand surface family while the gold fill
/// pops as a clear "I tapped this one" signal (the prior all-blue
/// recipe made selection invisible — empty and filled rendered the
/// same color). Sized for thumb-friendly taps (44dp min hit target),
/// generous spacing so the customer doesn't mis-tap between stars.
class RatingStarsRow extends StatelessWidget {
  const RatingStarsRow({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  /// 1-based rating (1..5), or null when nothing is selected yet.
  final int? rating;

  /// Tap callback. Always called with a value in [1, 5].
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        final filled = rating != null && starValue <= rating!;
        return _StarButton(
          starValue: starValue,
          filled: filled,
          onTap: () => onChanged(starValue),
        );
      }),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.starValue,
    required this.filled,
    required this.onTap,
  });

  final int starValue;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$starValue star${starValue == 1 ? '' : 's'}',
      selected: filled,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        // Ensure a 44dp minimum hit target without forcing visible
        // padding around the icon.
        containedInkWell: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              key: ValueKey<bool>(filled),
              size: 44,
              color: filled
                  ? OrchestratorPalette.ratingGold
                  : OrchestratorPalette.brandPrimary.withValues(alpha: 0.32),
            ),
          ),
        ),
      ),
    );
  }
}
