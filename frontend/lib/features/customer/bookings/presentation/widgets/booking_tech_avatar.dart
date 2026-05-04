import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Circular technician avatar with initials fallback.
///
/// Renders a [CachedNetworkImage] when [imageUrl] is non-null and
/// non-empty; otherwise computes initials from [displayName] (first
/// letter of the first word + first letter of the last word). Single-name
/// inputs degrade gracefully to the single initial; all-whitespace inputs
/// degrade to a blank tinted circle (no crash, no broken-image icon).
///
/// Sized at 48×48 by default per session_4 §5.3 — pass [size] to scale
/// down for compact contexts (e.g. detail-screen header).
class BookingTechAvatar extends StatelessWidget {
  const BookingTechAvatar({
    super.key,
    required this.imageUrl,
    required this.displayName,
    this.size = 48,
  });

  final String? imageUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => _initialsFallback(),
                errorWidget: (_, _, _) => _initialsFallback(),
              )
            : _initialsFallback(),
      ),
    );
  }

  Widget _initialsFallback() {
    final initials = _initialsOf(displayName);
    return Container(
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
