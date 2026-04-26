import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — primary action blue
  static const Color primary = Color(0xFF004AC6);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color inversePrimary = Color(0xFFB4C5FF);

  // Success / availability
  static const Color secondary = Color(0xFF006E2F);
  static const Color secondaryContainer = Color(0xFF6BFF8F);
  static const Color onSecondaryFixed = Color(0xFF002109);

  // Surfaces
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Text
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  // Feedback
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // CTA gradient (primaryContainer → primary, top→bottom)
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryContainer, primary],
  );
}
