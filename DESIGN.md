# DESIGN.md — Home Services Marketplace
> Design tokens extracted from the **Default Technician Cockpit** screen using the **FieldOps Precision** design system.
> Source: Stitch project `3379302216315648259` · Screen `6e3d02ee936c4e0db9d1a77780b5ad1b`
> Device target: 390×884 px mobile (standard Flutter portrait viewport)

---

## 1. Core Colors

All colors are from the `FieldOps Precision` design system's named-color palette. The system uses a **"High-Resolution Grayscale"** base so that Brand Blue and Success Green carry maximum visual weight.

### Brand / Action

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#004AC6` | Deep blue — gradient end, pressed states |
| `primary_container` | `#2563EB` | **Primary action blue** — CTAs, active nav, gradient start |
| `primary_fixed` | `#DBE1FF` | "In Progress" / "Scheduled" status chips |
| `inverse_primary` | `#B4C5FF` | Text/icons on dark primary surfaces |

> **CTA Gradient Rule:** Primary buttons use a vertical gradient `#2563EB → #004AC6`. Never flat-fill `#004AC6` alone.

### Success / Availability

| Token | Hex | Usage |
|---|---|---|
| `secondary` | `#006E2F` | **Success green** — "Online" toggle button fill |
| `secondary_container` | `#6BFF8F` | "Online" / "Complete" chip background |
| `on_secondary_container` | `#007432` | Text on success chips |
| `secondary_fixed` | `#6BFF8F` | Vibrant success indicator background |
| `on_secondary_fixed` | `#002109` | High-legibility text on vibrant chips |

### Surfaces & Backgrounds

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F8F9FA` | **App-wide off-white background** |
| `surface` | `#F8F9FA` | Main scaffold background (same as background) |
| `surface_container_low` | `#F3F4F5` | Large section / zone separators |
| `surface_container` | `#EDEEEF` | Mid-level containers |
| `surface_container_high` | `#E7E8E9` | Pressed/hover state on list items |
| `surface_container_highest` | `#E1E3E4` | Input field trays |
| `surface_container_lowest` | `#FFFFFF` | **Card surface white** — cards, primary inputs |
| `surface_dim` | `#D9DADB` | Disabled/dimmed surfaces |
| `surface_bright` | `#F8F9FA` | Elevated bright overlays |

> **"No-Line" Rule:** 1 px solid borders for section dividers are prohibited. Use background-color shifts between surface tiers instead.

### Typography Colors

| Token | Hex | Usage |
|---|---|---|
| `on_surface` | `#191C1D` | **Primary text** — headings, body copy |
| `on_surface_variant` | `#434655` | **Secondary text** — metadata, labels, captions |
| `on_background` | `#191C1D` | General body text on background |
| `outline` | `#737686` | Icon strokes, inactive nav icons |
| `outline_variant` | `#C3C6D7` | Ghost borders (15% opacity for data tables) |

### Feedback / System

| Token | Hex | Usage |
|---|---|---|
| `error` | `#BA1A1A` | Error state |
| `error_container` | `#FFDAD6` | Error chip / input highlight background |
| `on_error` | `#FFFFFF` | Text on error fill |
| `tertiary` | `#943700` | Warning / inspection-fee accent |
| `tertiary_container` | `#BC4800` | Warm-tone action (e.g. Rs. 500 fee badge) |
| `tertiary_fixed` | `#FFDBCD` | Warm chip backgrounds |

---

## 2. Typography

**Font Family:** `Inter` (body, headline, and label — all three roles use Inter).
**Letter-Spacing Strategy:** Headlines use `-0.02em` for an "engineered" authority feel. Labels use `+0.05em` for scanability.
**Hierarchy Strategy:** "Size-Skipping" — never place `body-lg` next to `title-sm`. Pair `headline-sm` with `label-md` for editorial contrast.

### Type Scale (Flutter `TextTheme` names → visual roles)

| Flutter Role | Size (sp) | Weight | Letter Spacing | Color Token | Screen Usage |
|---|---|---|---|---|---|
| `displayLarge` | 57 | 300 (Light) | -0.02em | `on_surface` | Hero metric numbers (e.g., total earnings) |
| `displayMedium` | 45 | 300 | -0.02em | `on_surface` | Secondary hero metrics |
| `headlineLarge` | 32 | 600 (SemiBold) | -0.02em | `on_surface` | Screen titles |
| `headlineMedium` | 28 | 600 | -0.02em | `on_surface` | Section group headers |
| `headlineSmall` | 24 | 600 | -0.02em | `on_surface` | **H2** — dashboard card section headings |
| `titleLarge` | 22 | 500 (Medium) | 0em | `on_surface` | **H1** — upcoming job card title, primary labels |
| `titleMedium` | 16 | 500 | +0.02em | `on_surface` | Job description, equipment names |
| `titleSmall` | 14 | 500 | +0.01em | `on_surface` | Sub-section labels |
| `bodyLarge` | 16 | 400 | 0em | `on_surface` | **Body** — general paragraph text |
| `bodyMedium` | 14 | 400 | 0em | `on_surface_variant` | Supporting body copy |
| `bodySmall` | 12 | 400 | 0em | `on_surface_variant` | Helper text, secondary descriptions |
| `labelLarge` | 14 | 500 | +0.05em | `on_surface_variant` | Button labels, tab labels |
| `labelMedium` | 12 | 500 | +0.05em | `on_surface_variant` | **Caption** — serial numbers, timestamps |
| `labelSmall` | 11 | 500 | +0.05em | `on_surface_variant` | Micro-labels, badge text |

---

## 3. Spacing & Shapes

### Base-8 Spacing Scale

All spacing values are multiples of 8 px. Use 4 px only for micro-gaps (icon-to-text, chip inner padding).

| Token Name | Value | Typical Usage |
|---|---|---|
| `space0` | 0 px | — |
| `space1` | 4 px | Icon-to-label gap, chip inner horizontal pad |
| `space2` | 8 px | Internal card row gaps, between chips |
| `space3` | 12 px | Tight list item vertical padding |
| `space4` | 16 px | **Standard card content padding**, list horizontal inset |
| `space5` | 20 px | Input field vertical padding |
| `space6` | 24 px | Section vertical gap, large card padding |
| `space8` | 32 px | Screen horizontal margin, section header margin-bottom |
| `space10` | 40 px | Large whitespace between screen sections |
| `space12` | 48 px | Bottom-nav height clearance |
| `space16` | 64 px | App-bar height, large hero padding |

### Component Padding Standards

| Component | Padding |
|---|---|
| Screen scaffold (horizontal) | 16 px left + right |
| Metric / summary card | 16 px all sides |
| Upcoming job card | 16 px horizontal, 12 px vertical |
| Bottom navigation bar | 12 px vertical, 24 px icon-to-label |
| Primary button | 16 px horizontal, 18 px vertical (min height 56 px) |
| Status chip | 8 px horizontal, 4 px vertical |
| Input field tray | 16 px horizontal, 14 px vertical |
| Section header row | 16 px horizontal, 8 px bottom |

### Border Radius

`ROUND_FOUR` scheme — the corner radius steps up in 4 px increments.

| Shape | Radius | Applied To |
|---|---|---|
| `shapeExtraSmall` | 4 px | Micro chips, badges, snackbar |
| `shapeSmall` | 8 px | **Buttons** (secondary, icon buttons), input bottom-bar focus ring |
| `shapeMedium` | 12 px | **Cards** (metric cards, job cards), dialog |
| `shapeLarge` | 16 px | Bottom sheet, large panel cards |
| `shapeExtraLarge` | 28 px | FAB, primary CTAs, avatar containers |
| `shapeFull` | 999 px | Pills (online toggle, availability chips) |

> **Glass Overlay Rule:** Floating overlays (status bars, action menus) use `surface` at 80% opacity with a `24 px` backdrop blur — never a hard background.

### Elevation

Shadows are reserved for "floating kinetic elements" only (e.g., Start Timer FAB).

| Level | Usage | Shadow spec |
|---|---|---|
| 0 | Base content, all list items | None — use tonal layering |
| 1 | Cards on `surface_container_low` | None — tonal shift provides lift |
| 2 | Floating action button | `blur: 16px, offset: (0,2), color: on_surface @6%` |
| 3 | Bottom navigation bar (glass) | `blur: 24px, surface @80%` |

---

## 4. Flutter Implementation

### Project Structure

Place all design tokens in `frontend/lib/core/theme/`:

```
lib/core/theme/
├── app_colors.dart        # Color constants
├── app_text_styles.dart   # TextTheme builder
├── app_shapes.dart        # ShapeTheme / BorderRadius constants
├── app_spacing.dart       # Spacing constants
└── app_theme.dart         # ThemeData assembly
```

### `app_colors.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary           = Color(0xFF004AC6);
  static const primaryContainer  = Color(0xFF2563EB);
  static const primaryFixed      = Color(0xFFDBE1FF);
  static const inversePrimary    = Color(0xFFB4C5FF);

  // Success / Availability
  static const secondary              = Color(0xFF006E2F);
  static const secondaryContainer     = Color(0xFF6BFF8F);
  static const onSecondaryContainer   = Color(0xFF007432);
  static const secondaryFixed         = Color(0xFF6BFF8F);
  static const onSecondaryFixed       = Color(0xFF002109);

  // Surfaces
  static const background                = Color(0xFFF8F9FA);
  static const surface                   = Color(0xFFF8F9FA);
  static const surfaceContainerLow       = Color(0xFFF3F4F5);
  static const surfaceContainer          = Color(0xFFEDEEEF);
  static const surfaceContainerHigh      = Color(0xFFE7E8E9);
  static const surfaceContainerHighest   = Color(0xFFE1E3E4);
  static const surfaceContainerLowest    = Color(0xFFFFFFFF);
  static const surfaceDim                = Color(0xFFD9DADB);

  // Text
  static const onSurface         = Color(0xFF191C1D);
  static const onSurfaceVariant  = Color(0xFF434655);
  static const outline           = Color(0xFF737686);
  static const outlineVariant    = Color(0xFFC3C6D7);

  // Feedback
  static const error          = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError        = Color(0xFFFFFFFF);

  // Warning / Inspection Fee accent
  static const tertiary          = Color(0xFF943700);
  static const tertiaryContainer = Color(0xFFBC4800);
  static const tertiaryFixed     = Color(0xFFFFDBCD);

  // CTA Gradient (primary_container → primary)
  static const ctaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [primaryContainer, primary],
  );
}
```

### `app_spacing.dart`

```dart
abstract final class AppSpacing {
  static const double s0  = 0;
  static const double s1  = 4;
  static const double s2  = 8;
  static const double s3  = 12;
  static const double s4  = 16;   // standard card padding
  static const double s5  = 20;
  static const double s6  = 24;
  static const double s8  = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  // Named semantic aliases
  static const double cardPadding    = s4;
  static const double screenPadding  = s4;
  static const double sectionGap     = s6;
  static const double buttonHeight   = 56;
}
```

### `app_shapes.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppShapes {
  static const extraSmall  = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)));
  static const small       = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)));
  static const medium      = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
  static const large       = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
  static const extraLarge  = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28)));
  static const full        = StadiumBorder();

  // Convenience radius values for BorderRadius.circular(...)
  static const double radiusXS  = 4;
  static const double radiusSM  = 8;
  static const double radiusMD  = 12;   // cards
  static const double radiusLG  = 16;
  static const double radiusXL  = 28;   // FAB, primary CTA
}
```

### `app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

TextTheme buildAppTextTheme() {
  final base = GoogleFonts.interTextTheme();
  return base.copyWith(
    displayLarge:   base.displayLarge!.copyWith(fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -1.14, color: AppColors.onSurface),
    displayMedium:  base.displayMedium!.copyWith(fontSize: 45, fontWeight: FontWeight.w300, letterSpacing: -0.90, color: AppColors.onSurface),
    headlineLarge:  base.headlineLarge!.copyWith(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.64, color: AppColors.onSurface),
    headlineMedium: base.headlineMedium!.copyWith(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.56, color: AppColors.onSurface),
    headlineSmall:  base.headlineSmall!.copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.48, color: AppColors.onSurface),
    titleLarge:     base.titleLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.onSurface),
    titleMedium:    base.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.32, color: AppColors.onSurface),
    titleSmall:     base.titleSmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.14, color: AppColors.onSurface),
    bodyLarge:      base.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface),
    bodyMedium:     base.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),
    bodySmall:      base.bodySmall!.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),
    labelLarge:     base.labelLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.70, color: AppColors.onSurfaceVariant),
    labelMedium:    base.labelMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.60, color: AppColors.onSurfaceVariant),
    labelSmall:     base.labelSmall!.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.55, color: AppColors.onSurfaceVariant),
  );
}
```

### `app_theme.dart` — Full ThemeData Assembly

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness:             Brightness.light,
      primary:                AppColors.primary,
      onPrimary:              Color(0xFFFFFFFF),
      primaryContainer:       AppColors.primaryContainer,
      onPrimaryContainer:     Color(0xFFEEEFFF),
      secondary:              AppColors.secondary,
      onSecondary:            Color(0xFFFFFFFF),
      secondaryContainer:     AppColors.secondaryContainer,
      onSecondaryContainer:   AppColors.onSecondaryContainer,
      tertiary:               AppColors.tertiary,
      onTertiary:             Color(0xFFFFFFFF),
      tertiaryContainer:      AppColors.tertiaryContainer,
      onTertiaryContainer:    Color(0xFFFFEDE6),
      error:                  AppColors.error,
      onError:                AppColors.onError,
      errorContainer:         AppColors.errorContainer,
      onErrorContainer:       Color(0xFF93000A),
      surface:                AppColors.surface,
      onSurface:              AppColors.onSurface,
      onSurfaceVariant:       AppColors.onSurfaceVariant,
      outline:                AppColors.outline,
      outlineVariant:         AppColors.outlineVariant,
      inverseSurface:         Color(0xFF2E3132),
      onInverseSurface:       Color(0xFFF0F1F2),
      inversePrimary:         AppColors.inversePrimary,
      surfaceTint:            Color(0xFF0053DB),
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme:               buildAppTextTheme(),

    // Cards — medium radius (12 px), white surface, tonal lift only
    cardTheme: const CardThemeData(
      color:        AppColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation:    0,
      shape:        AppShapes.medium,
      margin:       EdgeInsets.zero,
    ),

    // Primary elevated button — gradient + xl radius (28 px)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize:     WidgetStatePropertyAll(Size(double.infinity, 56)),
        shape:           WidgetStatePropertyAll(AppShapes.extraLarge),
        elevation:       WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(AppColors.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
        textStyle:       WidgetStatePropertyAll(TextStyle(
          fontFamily:     'Inter',
          fontSize:       14,
          fontWeight:     FontWeight.w500,
          letterSpacing:  0.70,
        )),
      ),
    ),

    // Outlined / secondary button — small radius (8 px)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize:     WidgetStatePropertyAll(Size(double.infinity, 48)),
        shape:           WidgetStatePropertyAll(AppShapes.small),
        side:            WidgetStatePropertyAll(BorderSide(color: AppColors.outline)),
        foregroundColor: WidgetStatePropertyAll(AppColors.primary),
      ),
    ),

    // Chips — pill shape for availability, fixed for status
    chipTheme: ChipThemeData(
      shape:           const StadiumBorder(),
      backgroundColor: AppColors.primaryFixed,
      selectedColor:   AppColors.secondaryContainer,
      labelStyle:      const TextStyle(
        fontFamily:    'Inter',
        fontSize:      12,
        fontWeight:    FontWeight.w500,
        letterSpacing: 0.60,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // Bottom nav — glass effect applied manually via BackdropFilter in widget
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:      AppColors.surfaceContainerLowest,
      indicatorColor:       AppColors.primaryFixed,
      iconTheme:            WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.outline, size: 24);
      }),
      labelTextStyle:       WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
        }
        return const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.outline);
      }),
      elevation:    0,
      height:       64,
    ),

    // Inputs — Soft Tray: surfaceContainerHighest bg, 2 px primary underline on focus
    inputDecorationTheme: const InputDecorationTheme(
      filled:           true,
      fillColor:        AppColors.surfaceContainerHighest,
      border:           UnderlineInputBorder(borderSide: BorderSide.none),
      focusedBorder:    UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryContainer, width: 2)),
      contentPadding:   EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle:        TextStyle(color: AppColors.onSurfaceVariant),
    ),

    // Dividers — invisible, tonal separation handles it
    dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:  AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      scrolledUnderElevation: 0,
      titleTextStyle:   TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    ),
  );
}
```

### Riverpod / Clean Architecture Wiring

In a Riverpod + Clean Architecture setup, the theme is **not** a provider (it does not change at runtime for this app — no dark mode yet). Expose it from `main.dart` directly:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,
      // darkTheme: AppTheme.dark,  // add when dark mode is scoped
      routerConfig: appRouter,
    );
  }
}
```

**If dynamic theming is ever needed** (e.g., user-selectable accent color), promote it to Riverpod:

```dart
// lib/core/theme/providers/theme_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../app_theme.dart';
import 'package:flutter/material.dart';

part 'theme_provider.g.dart';

@riverpod
ThemeData appTheme(AppThemeRef ref) => AppTheme.light;
```

Then consume in widgets:

```dart
// In any widget
final theme = ref.watch(appThemeProvider);
```

**Widget usage pattern** — always consume via `Theme.of(context)`, never hardcode `AppColors` directly in widgets:

```dart
// Good — respects the ThemeData contract
Text('Jobs Today', style: Theme.of(context).textTheme.headlineSmall)
Container(color: Theme.of(context).colorScheme.surface)

// Bad — bypasses the theme contract
Text('Jobs Today', style: TextStyle(fontSize: 24, color: Color(0xFF191C1D)))
```

---

## Quick-Reference Cheat Sheet

```
Primary Blue    #2563EB   → CTAs, active states, gradient start
Deep Blue       #004AC6   → gradient end, pressed
Success Green   #006E2F   → Online toggle button
Vibrant Green   #6BFF8F   → Complete/Online chip background
Background      #F8F9FA   → Scaffold
Card Surface    #FFFFFF   → Cards, inputs
Primary Text    #191C1D   → All headings, body
Secondary Text  #434655   → Metadata, captions, labels

Card radius     12 px
Button radius   28 px (primary CTA) / 8 px (secondary)
Chip radius     pill (999 px)
Card padding    16 px
Screen padding  16 px
Button height   56 px (min, for gloved-tap compliance)
Base unit       8 px
Font            Inter (all weights)
```
