import 'dart:io';

import 'package:flutter/material.dart';

/// Upload-target card used across the onboarding wizard (profile picture,
/// CNIC photo, license photos). Visual language matches the brand
/// ``#0051AE`` rounded ElevatedButton used elsewhere in the project.
///
/// Two states:
///   * ``isUploaded = false`` — outlined card with a camera glyph and a
///     short prompt.
///   * ``isUploaded = true`` — soft-tinted card with a 56x56 THUMBNAIL of
///     the captured frame (when ``localPreviewPath`` is provided) and a
///     "Tap to retake" subtitle. The thumbnail is the load-bearing
///     verification — the user must see what they captured before they
///     commit to it, otherwise blurry / off-frame photos slip through
///     onboarding without anyone noticing.
class AnimatedUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isUploaded;
  final VoidCallback onTap;
  final IconData glyph;
  final String? localPreviewPath;

  const AnimatedUploadCard({
    super.key,
    required this.title,
    required this.description,
    required this.isUploaded,
    required this.onTap,
    this.glyph = Icons.camera_alt_outlined,
    this.localPreviewPath,
  });

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isUploaded ? const Color(0xFFEFF4FB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUploaded ? _brand : const Color(0xFFE3E6EF),
              width: isUploaded ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Leading(
                isUploaded: isUploaded,
                glyph: glyph,
                localPreviewPath: localPreviewPath,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF151C24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploaded ? 'Tap to retake' : description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isUploaded ? _brand : const Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUploaded)
                const Icon(Icons.check_circle, color: _brand, size: 22)
              else
                const Icon(Icons.chevron_right, color: Color(0xFF9AA3B2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final bool isUploaded;
  final IconData glyph;
  final String? localPreviewPath;
  const _Leading({
    required this.isUploaded,
    required this.glyph,
    required this.localPreviewPath,
  });

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    // Thumbnail when uploaded AND we still have the local file path —
    // ImagePicker drops a temp file we can render until the wizard
    // completes. Falls back to the glyph if the file is gone (e.g.
    // OS swept the cache between picks).
    if (isUploaded && localPreviewPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(localPreviewPath!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _glyphTile(),
        ),
      );
    }
    return _glyphTile();
  }

  Widget _glyphTile() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isUploaded ? _brand : const Color(0xFFEFF4FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          glyph,
          size: 22,
          color: isUploaded ? Colors.white : _brand,
        ),
      );
}
