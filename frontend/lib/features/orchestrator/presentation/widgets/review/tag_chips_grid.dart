import 'package:flutter/material.dart';

import '../../../domain/entities/review.dart';
import '../_palette/orchestrator_palette.dart';

/// Wraps a list of [PredefinedTag] chips, each toggleable. The set is
/// rendered as a `Wrap` so chips flow naturally across multiple lines
/// on narrow phones.
///
/// The parent (`BookingReviewBody`) decides which tag bucket to pass
/// based on the user's selected rating — this widget itself is purely
/// presentational.
///
/// Empty `tags` is rendered as a [SizedBox.shrink] — the parent should
/// only pass an empty list when it explicitly wants to hide the chip
/// row (e.g. no rating selected yet).
class TagChipsGrid extends StatelessWidget {
  const TagChipsGrid({
    super.key,
    required this.tags,
    required this.selectedKeys,
    required this.onToggle,
  });

  final List<PredefinedTag> tags;
  final Set<String> selectedKeys;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: tags.map((t) {
        final selected = selectedKeys.contains(t.key);
        return _TagChip(
          label: t.label,
          selected: selected,
          onTap: () => onToggle(t.key),
        );
      }).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Color tokens: selected uses brand-primary fill + white label;
    // unselected uses light tint + brand-primary label. Mirrors the
    // existing booking-flow ElevatedButton language per the user's
    // feedback memory (visual identity is the existing brand blue,
    // not Foodpanda's orange).
    final bg = selected
        ? OrchestratorPalette.brandPrimary
        : OrchestratorPalette.brandPrimaryTint06;
    final fg = selected ? Colors.white : OrchestratorPalette.brandPrimary;
    final border = selected
        ? OrchestratorPalette.brandPrimary
        : OrchestratorPalette.brandPrimary.withValues(alpha: 0.24);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
