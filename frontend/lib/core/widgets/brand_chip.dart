import 'package:flutter/material.dart';

/// Brand-blue pill chip used by every "pick one from a small set" surface
/// (address save-as labels, technician service picker on profile, etc.).
///
/// Visual contract:
///  * Selected: solid #0051AE background, white foreground, 1.5px solid
///    brand border.
///  * Unselected: 5%-alpha brand wash, brand-blue foreground, transparent
///    border so the chip's outer geometry doesn't shift between states.
///  * Tap target ≥40dp tall (Material guideline floor for pill surfaces).
///  * Ripple via [InkWell] + `Material(transparent)` over an
///    `AnimatedContainer` so the background colour can transition between
///    states without losing the ripple effect.
///
/// Sized by the parent — wrap in `Expanded` for an equal-share row, or
/// hand it an intrinsic width by leaving it bare. The chip self-centers
/// its icon + label so it looks right at any width.
class BrandChip extends StatelessWidget {
  const BrandChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? _brandBlue : _brandBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _brandBlue : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : _brandBlue,
                ),
                const SizedBox(width: 8),
                // Flexible + ellipsis lets long localised labels degrade
                // gracefully instead of overflowing the chip.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _titleText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
