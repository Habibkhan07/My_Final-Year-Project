# Session 4 — Customer Bookings List UI (production / market-competitive)

> **Sprint goal**: Build the customer-facing **My Bookings** list screen that consumes the already-shipped data layer, ship it at competitive-market quality (Uber/Airbnb/Foodpanda calibre on its scope), wire the bottom-nav tab, register the route, and fold flag #27 closed.
>
> **Closes**: flag #27 — *Customer bookings list feature stack landed without UI*.
>
> **Visual reference**: Stitch project `3379302216315648259`, screens `153eda9c56854c0c865e202257e1e7c8` (*"My Bookings - Upcoming (Polished)"*) and `873809652fe94ae2b2f9be0ffefd3f32` (*"My Bookings - Past (Polished)"*). The two screens have known issues you MUST NOT copy — see §13.

---

## §0. SOURCE-OF-TRUTH PRECEDENCE — read this first

When sources conflict (and they do, in specific places), apply this precedence:

| # | Source | Wins for |
|---|---|---|
| 1 | `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` (esp. §1.4 + §1.7) | All **copy** — pill text, headline text, price context, status enum. **Server emits, client renders verbatim.** |
| 2 | This file (`session_4_*.md`) | Component contracts, state branches (data/skeleton/empty/error/offline), animation timing, file plan, dumb-UI rules. |
| 3 | Stitch screens (above IDs) | Visual **tokens** only — colors, typography, spacing, card chrome, avatar treatment, pill geometry. |
| 4 | Project conventions (`CLAUDE.md`, existing widgets) | Anything else — Riverpod, route registration, hero tags, theme integration. |

**Critical inversions** (you WILL get these wrong if you don't internalise the table):

- The Stitch designs show pill text `PENDING` — **the wire emits `Awaiting tech`**. Server wins.
- Stitch shows headline `"Cancelled booking with Usman Ali"` — **the wire emits `"You cancelled this booking"`**. Server wins.
- Stitch shows price context `Estimated` — **the wire never emits this**. The server's `price.context` is `Fixed Price` / `Labor Fee` / `Inspection Fee` / `""`.
- Stitch's two screens use *different* card layouts. **Use ONE BookingCard for both segments.** Stitch lost.
- Stitch hides price on Cancelled cards. **Always render `price.uiLabel`** — info preservation. Stitch lost.

This is the dumb-UI principle in operational form. If you find yourself writing `if (status == awaiting) text = "Awaiting tech"`, stop. Read `ui.badgeText`. The whole data sprint exists to make this widget dumb.

---

## §1. Mandatory pre-reads

Before writing a single line:

1. **`backend/bookings/api/CUSTOMER_BOOKINGS_API.md`** — wire contract. §1.4 lists every field; §1.7 is the canonical status → ui table.
2. **`frontend/lib/features/customer/bookings/CUSTOMER_BOOKINGS_FEATURE.md`** — what's wired. Marks `presentation/screens` as ⏳ pending — that's *this* sprint.
3. **`flag.md` flag #27** — what was deferred and why.
4. **`CLAUDE.md` — Frontend section** — Riverpod rules (`@riverpod`, `state.requireValue`, `AsyncValue.guard`), Dumb UI principle, error-propagation pipeline. Non-negotiable.
5. **Stitch reference screens** (visual tokens only, see §3 for what to extract):
   - Upcoming: `projects/3379302216315648259/screens/153eda9c56854c0c865e202257e1e7c8`
   - Past: `projects/3379302216315648259/screens/873809652fe94ae2b2f9be0ffefd3f32`
6. **Reference impls to cargo-cult code from**:
   - `frontend/lib/features/customer/home/presentation/screens/home_screen.dart` — bottom-nav scaffolding (currently broken — see §10).
   - `frontend/lib/features/customer/home/presentation/widgets/home_skeleton_loader.dart` — skeleton pattern.
   - `frontend/lib/features/customer/home/presentation/widgets/offline_banner.dart` — offline UX language.
   - `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/` — most polished feature; steal animation timing.
   - `frontend/lib/features/customer/discovery/presentation/providers/discovery_notifier.dart` — `state.value` access pattern, `copyWithPrevious`.

---

## §2. What is already built (do NOT rebuild)

The entire **data + domain + presentation/providers** stack landed in commits `d70dee5`, `1657a91`, `08c113a`, `71f5748`. **Do not modify those layers.** You are *consuming* them.

| Provider | Type | Use |
|---|---|---|
| `customerBookingsListProvider` | `AsyncValue<CustomerBookingsListState>` | `ref.watch` for the list state |
| `customerBookingsCountsProvider` | `AsyncValue<BookingsCounts>` | `ref.watch` for badge counts |
| `selectedSegmentProvider` | `BookingSegment` | `ref.watch` for active segment |

| Method | Effect |
|---|---|
| `customerBookingsListProvider.notifier.refresh()` | Pull-to-refresh re-fetches first page |
| `customerBookingsListProvider.notifier.loadMore()` | Append next page (idempotent + guarded) |
| `customerBookingsCountsProvider.notifier.refresh()` | Refetch counts |
| `selectedSegmentProvider.notifier.set(BookingSegment)` | Switch tabs; triggers list rebuild |

**Realtime patches are automatic.** The list notifier already subscribes to `systemEventProvider` and patches items on `jobAccepted` / `bookingRejected`. No `ref.listen` needed in widgets — `ref.watch(customerBookingsListProvider)` and the AsyncData updates on its own. **Animations are your responsibility** (see §8).

**The boot hook is wired.** Both providers are in `realtimeBootHooksProvider`. They wake at boot.

---

## §3. Visual design system — concrete tokens (extracted from Stitch)

These are **the** tokens. Do not invent your own. Translate directly into Flutter `ColorScheme`, `TextTheme`, and design constants. If the project's existing `core/theme/` already exposes these as named tokens, use those names and skip the literals here.

### §3.1 Colors — Material 3 ColorScheme

| ColorScheme member | Hex | Stitch token | Use |
|---|---|---|---|
| `primary` | `#0037ab` | `primary` | Brand actions, focused state, primary price |
| `onPrimary` | `#ffffff` | `on-primary` | — |
| `primaryContainer` | `#1f4fd1` | `primary-container` | Bottom-nav active label color |
| `onPrimaryContainer` | `#c8d2ff` | `on-primary-container` | — |
| `secondary` | `#006c49` | `secondary` | — |
| `secondaryContainer` | `#7ef6be` | `secondary-container` | Status pill bg — **positive** tone (CONFIRMED/COMPLETED) |
| `onSecondaryContainer` | `#00714c` | `on-secondary-container` | Status pill fg — positive tone |
| `tertiary` | `#693600` | `tertiary` | — |
| `tertiaryFixedDim` | `#ffb77d` | `tertiary-fixed-dim` | Status pill bg — **warning** tone (AWAITING) |
| `onTertiaryFixed` | `#2f1500` | `on-tertiary-fixed` | Status pill fg — warning tone |
| `error` | `#ba1a1a` | `error` | — |
| `errorContainer` | `#ffdad6` | `error-container` | Status pill bg — **negative** tone (REJECTED/CANCELLED) |
| `onErrorContainer` | `#93000a` | `on-error-container` | Status pill fg — negative tone |
| `surface` | `#faf8ff` | `surface` / `background` | Page background |
| `surfaceContainerLowest` | `#ffffff` | `surface-container-lowest` | Card bg |
| `surfaceContainerLow` | `#f3f2fe` | `surface-container-low` | Subtle alt surface (e.g. nested detail block, empty-state illustration bg) |
| `surfaceContainer` | `#ededf8` | `surface-container` | — |
| `surfaceContainerHigh` | `#e8e7f2` | `surface-container-high` | Segmented control track bg |
| `surfaceContainerHighest` | `#e2e1ed` | `surface-container-highest` | Card border (faint) |
| `onSurface` | `#1a1b23` | `on-surface` | Headline text |
| `onSurfaceVariant` | `#434654` | `on-surface-variant` | Meta text (date / address) |
| `outline` | `#747686` | `outline` | Icon color in meta rows |
| `outlineVariant` | `#c4c5d7` | `outline-variant` | Card divider, AppBar bottom border |

**Tone-to-color resolver** (single source of truth — implement once, reuse):

```dart
// presentation/utils/booking_tone_palette.dart
class BookingTonePalette {
  final Color background;
  final Color foreground;
  const BookingTonePalette(this.background, this.foreground);

  static BookingTonePalette of(BookingUiTone tone, ColorScheme c) {
    switch (tone) {
      case BookingUiTone.positive:
        return BookingTonePalette(c.secondaryContainer, c.onSecondaryContainer);
      case BookingUiTone.warning:
        // Stitch uses tertiary-fixed-dim/20 (20% opacity) bg with full fg.
        return BookingTonePalette(
          c.tertiaryFixedDim.withValues(alpha: 0.20),
          c.onTertiaryFixed,
        );
      case BookingUiTone.negative:
        // Stitch uses error-container/30 bg with on-error-container fg.
        return BookingTonePalette(
          c.errorContainer.withValues(alpha: 0.30),
          c.onErrorContainer,
        );
      case BookingUiTone.neutral:
      case BookingUiTone.unknown:
        return BookingTonePalette(
          c.surfaceContainerHigh,
          c.onSurfaceVariant,
        );
      case BookingUiTone.info:
        // Reserved for future events. Use primaryContainer-tinted.
        return BookingTonePalette(
          c.primaryContainer.withValues(alpha: 0.15),
          c.primary,
        );
    }
  }
}
```

### §3.2 Typography — Inter, Material 3 scale

Map directly into the project's `TextTheme`. If the theme already has these, use them.

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| `h1` (display-small-ish) | 32 | 700 | 40 | Reserved (not used on this screen) |
| `h2` (title-large) | 24 | 700 | 32 | AppBar (if larger than h3) |
| `h3` (title-medium) | 20 | 600 | 28 | Card headline (`ui.headline`), AppBar title, primary price |
| `body-lg` | 18 | 400 | 28 | Reserved |
| `body-md` | 16 | 400 | 24 | Meta row text (date / address) |
| `label-bold` | 14 | 700 | 20 | Segmented control text, secondary price |
| `label-sm` | 12 | 600 | 16 | Service label (uppercase tracking-wider), pill text, price context |

Font: **Inter** with weights 400 / 500 / 600 / 700. Material Symbols Outlined for icons.

### §3.3 Spacing tokens

| Token | Value |
|---|---|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `gutter` | 16 (horizontal screen padding) |
| `margin` | 20 (component margin where needed) |

### §3.4 Card chrome

| Property | Value |
|---|---|
| Background | `surfaceContainerLowest` (`#ffffff`) |
| Border radius | `12` (Stitch's `rounded-xl` = 0.75rem = 12pt) |
| Border | `1px` solid `outlineVariant.withValues(alpha: 0.30)` (Stitch's `border-outline-variant/30`) |
| Shadow | `BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: Offset(0, 4))` |
| Hover/focus shadow | upgrade to `alpha: 0.08`, `blurRadius: 24`, `offset: Offset(0, 8)` (mobile rarely uses hover; keep for desktop emulator) |
| Press state | `scale: 0.98` (Stitch's `active:scale-[0.98]`) |
| Padding | `16` all sides |
| Vertical gap between cards | `12` (16 if padding doesn't already create the 12 visually — match the Stitch screenshot) |

### §3.5 Status pill geometry

| Property | Value |
|---|---|
| Padding | `8` horizontal, `2` vertical (tighter than typical M3 chips — matches Stitch) |
| Border radius | `9999` (fully rounded, Stitch's `rounded-full`) |
| Border | `1px` solid same-tone-bg at higher alpha (Stitch uses `border-{tone}/{30..50}`) |
| Text | `label-sm` (12/16, weight 600), `letter-spacing: 0.05em` (Stitch's `tracking-wider`), `text-transform: uppercase` |
| Width | hug content; no min/max |
| Leading dot indicator (●) | **Skip.** Stitch doesn't use one. |

### §3.6 Segmented control

| Property | Value |
|---|---|
| Track bg | `surfaceContainerHigh` (`#e8e7f2`) |
| Track padding | `4` |
| Track border radius | `8` (Stitch's `rounded-lg`) |
| Active segment bg | `surfaceContainerLowest` (`#ffffff`) |
| Active segment text | `primary` (`#0037ab`), `label-bold` (14/20 weight 700) |
| Active segment shadow | subtle `0 1px 2px rgba(0,0,0,0.05)` (Stitch's `shadow-sm`) |
| Inactive segment text | `onSurfaceVariant` |
| Segment padding | `8` vertical, `16` horizontal |
| Segment border radius | `4` (Stitch's `rounded` default = 0.25rem = 4pt) |
| Width | `max-w-md` (~448) full inside the screen container |

### §3.7 Bottom navigation

Already defined elsewhere in the codebase but for reference (Stitch matches the project's existing nav):

| Property | Value |
|---|---|
| Bg | `surfaceContainerLowest` (`#ffffff`) |
| Height | `80` (Stitch's `h-20`) |
| Active icon weight | filled (Material Symbols `FILL: 1`) |
| Active label color | `primaryContainer` (`#1f4fd1`) |
| Active item bg | `primaryContainer.withValues(alpha: 0.10)` rounded `12` (Stitch's `bg-blue-50` + `rounded-xl`) |
| Inactive label color | `outline` |
| Top shadow | `0 -4px 12px rgba(0,0,0,0.05)` |

---

## §4. Screen layout

```
┌─────────────────────────────────────────────┐
│  My Bookings                                │  AppBar — h3, primary color, sticky
├─────────────────────────────────────────────┤
│  ⚠ Offline · last updated 8 min ago      ↻  │  Optional offline strip (only when isStaleCache)
├─────────────────────────────────────────────┤
│  ┌────────────────────┐ ┌──────────────────┐│
│  │ Upcoming     · 1   │ │ Past         · 12││  Segmented control
│  └────────────────────┘ └──────────────────┘│
├─────────────────────────────────────────────┤
│                                              │
│  ┌──── BookingCard ─────────────────────────┐│
│  │ [svg] AC REPAIR              [● Confirmed]││  Header row (svg=service icon, small)
│  │                                           ││
│  │ [👤] Confirmed with Ahmed Khan           ││  Avatar 48px + headline h3
│  │      ─────────────────────────           ││
│  │      📍 Home — DHA Phase 5, Lahore       ││  Meta row 1
│  │      🗓 Tomorrow, 3:00 PM                ││  Meta row 2 (no end time)
│  │      💳 Fixed Price        Rs. 2,500     ││  Price row (left = context, right = uiLabel)
│  └───────────────────────────────────────────┘│
│                                              │
│  ┌──── BookingCard ─────────────────────────┐│  More cards…
│  │  ...                                      ││
│  └───────────────────────────────────────────┘│
│                                              │
│  ┌─[ small spinner — pagination footer ]────┐│  Only when isLoadingMore
│  └───────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

### §4.1 AppBar
- Title: `"My Bookings"` (NOT empty — Stitch's Past screen has an empty `<br>` tag bug; do NOT copy that).
- Color: `primary` (`#0037ab`), `h3` (Inter 20/28 weight 600).
- Position: sticky, full-width, bottom border `1px outlineVariant`, height `64`.
- No back arrow — it's a tab destination, not a pushed route.
- No trailing actions in v1.

### §4.2 Segmented control
- Material 3 `SegmentedButton<BookingSegment>` directly below the AppBar.
- Two segments: `Upcoming` and `Past`. Append count badge from `customerBookingsCountsProvider` using `·` separator: `Upcoming · 1`, `Past · 12`.
- When counts is `AsyncLoading` or `AsyncError`, render `Upcoming` / `Past` without a count (no `· —` placeholder — clean omission is less noisy).
- `onSelectionChanged` → `ref.read(selectedSegmentProvider.notifier).set(...)`. The list rebuilds automatically.
- Tokens per §3.6.
- Horizontal margin from screen edges: `16` (matches `gutter`). Bottom margin to list: `24` (Stitch's `mb-6`/`mb-8`).

### §4.3 List body
- `RefreshIndicator` wrapping a `ListView.builder`.
- Pull-to-refresh: in parallel `await Future.wait([listNotifier.refresh(), countsNotifier.refresh()])`.
- Pre-fetch trigger: when scroll position is within 3 cards of the end → `loadMore()` (notifier guards re-entry).
- Card spacing: `12` vertical, `16` horizontal padding inside screen.
- Surrounding bg: `surface` (the page bg from §3.1).

---

## §5. The `BookingCard` widget — ONE component, both segments

`StatelessWidget` taking a single `CustomerBooking` entity. This is the most important section in the brief. **Stitch shipped two different card layouts; you SHIP ONE.**

The same widget renders an Upcoming `CONFIRMED` card and a Past `CANCELLED` card. The only differences across statuses are:

- Status pill copy + tone (server-driven via `ui.badgeText` + `ui.badgeTone`)
- Headline copy (server-driven via `ui.headline`)
- "Cancelled visual decay" treatment (one extra modifier, see §5.6)

**Switch on `ui.badgeTone` for design tokens. Never on raw `status` for copy.** This is the dumb-UI principle in code form.

### §5.1 Card chrome
Per §3.4. Wrap an `InkWell` for ripple + tap. Hero-tag the service icon as `'booking-icon-${item.id}'` for the future detail-screen morph.

### §5.2 Region 1 — Header row (top)

Two columns; `Row` with `MainAxisAlignment.spaceBetween`, `CrossAxisAlignment.start`.

**Left**: small service identifier
- Service SVG icon (24×24) via `IconAssets.path(item.service.iconName)`. Color: `outline`.
- Small gap (`8`).
- `service.name` in `label-sm`, uppercase, `letter-spacing: 0.08em`, `outline` color.

**Right**: status pill per §3.5 + §3.5's tone resolver.

**Resolved decision (was an open question in the prior spec)**: We keep BOTH the service icon and the tech avatar. The icon is a small monochrome decoration in the top-left header label; the avatar is the prominent 48px image in §5.3. This honours both the `IconAssets.path()` project convention AND the humanised avatar treatment Stitch popularised.

### §5.3 Region 2 — Headline row

Two columns; `Row` with `crossAxisAlignment: CrossAxisAlignment.center`, top margin `12` from header.

**Left**: tech avatar
- 48×48 `CircleAvatar` from `item.technician.profilePictureUrl`.
- Background fallback: `surfaceContainer`. Foreground fallback: tech display name initials (first letter of first word + first letter of last word, uppercase) in `label-bold`, `onSurfaceVariant`.
- When `profilePictureUrl == null`, render the initials fallback. NEVER render a broken-image icon.

**Right**: headline
- `ui.headline` rendered verbatim from the server. NEVER reformat or recompose.
- Style: `h3` (Inter 20/28 weight 600), `onSurface`. Multi-line allowed up to 2 lines, then ellipsis.
- Left margin from avatar: `12`.

### §5.4 Region 3 — Meta row (date + address)

Below the headline row, with `12` top margin and a `1px outlineVariant.withValues(alpha:0.30)` divider above (Stitch's `border-t border-surface-container-high pt-4`).

Two stacked rows, each:
- 18×18 Material Symbols icon, `outline` color.
- `8` gap.
- Text in `body-md` (16/24 weight 400), `onSurfaceVariant`.

| Row | Icon | Text |
|---|---|---|
| Date | `schedule` | Smart-formatted date string (see §6) |
| Address | `location_on` | `addressLabel` rendered verbatim |

**Hide the address row entirely if `addressLabel == null`.** Do NOT render a placeholder.

### §5.5 Region 4 — Price row

Below the meta row, with `8` top margin and another `1px` divider above (separating meta from price).

`Row`, `MainAxisAlignment.spaceBetween`, `CrossAxisAlignment.center`:

**Left**: price context
- 18×18 Material Symbols `payments` icon, `outline` color.
- `8` gap.
- `price.context` in `label-sm`, `onSurfaceVariant`. **If `price.context == ""`**, hide the icon + text entirely (rare; defensive).

**Right**: primary price label
- `price.uiLabel` in `h3` (20/28 weight 600), color `primary` (`#0037ab`).
- For Cancelled bookings: still render. Apply opacity 0.7. Do NOT line-through (the user might still owe the inspection fee — line-through implies "no charge").

### §5.6 Cancelled visual treatment

When `status == BookingStatus.cancelled`:
- Card container: `opacity: 0.85`.
- Address row text: `decoration: TextDecoration.lineThrough`, `decorationColor: outlineVariant`.
- Date row: opacity 0.85 on the text only.
- Price row: opacity 0.7 on the price label (per §5.5).

These are CSS-side modifiers — DO NOT change layout, copy, or component structure. Same widget, decorated.

### §5.7 Tap target + interactions
- Entire card body is the tap target (excluding the future kebab menu position — don't render a kebab in v1).
- `onTap` → `context.push('/customer/booking/${booking.id}')`.
- Press state: `scale: 0.98` (Stitch convention).
- Haptic on tap: `HapticFeedback.lightImpact()`.

### §5.8 What a complete render looks like (per status)

These come from the server's `_resolve_ui_block` table. Your widget renders verbatim.

| Status | Header label | Pill text | Pill tone | Headline | Cancelled treatment? |
|---|---|---|---|---|---|
| AWAITING | service.name (uppercase) | "Awaiting tech" | warning | `"Waiting for {tech} to confirm"` | no |
| CONFIRMED | service.name | "Confirmed" | positive | `"Confirmed with {tech}"` | no |
| COMPLETED | service.name | "Completed" | positive | `"Completed by {tech}"` | no |
| CANCELLED | service.name | "Cancelled" | neutral | `"You cancelled this booking"` | **yes** |
| REJECTED + technician_declined | service.name | "Unavailable" | negative | `"{tech} couldn't take this"` | no |
| REJECTED + sla_timeout | service.name | "Timed out" | negative | `"{tech} didn't respond in time"` | no |
| PENDING (legacy) | service.name | "Pending" | neutral | `"Booking is being prepared"` | no |

Note `CANCELLED` uses **neutral** tone, not negative — this matches the API §1.7 table. The Stitch design uses an error-container pill (red) for Cancelled; we override with neutral per the canonical table.

---

## §6. Smart date formatting — client-side

The card's date row uses a single helper. Anchor on `state.serverTime` — NOT `DateTime.now()` — so device-clock skew can't misrepresent imminence.

### §6.1 Lookup table

Implement in `presentation/utils/date_formatter.dart`:

```dart
String formatBookingDate(
  DateTime scheduledStart,
  DateTime serverNow,
  BookingStatus status,
  // Optional: SLA expiry from realtime envelope when available.
  DateTime? expiresAt,
);
```

| When `scheduledStart` falls relative to `serverNow` | Display |
|---|---|
| 0–60 min ahead | `"In 30 min"` |
| 0–60 min ago | `"30 min ago"` |
| Today, > 60 min ahead, same calendar day | `"Today, 3:00 PM"` |
| Today, past, same calendar day | `"Today, 11:00 AM"` |
| Tomorrow (calendar) | `"Tomorrow, 3:00 PM"` |
| Within next 6 days | `"Friday, 3:00 PM"` |
| This year, otherwise | `"Mar 8, 3:00 PM"` |
| Other year | `"Mar 8, 2025, 3:00 PM"` |

Use `intl` package's `DateFormat`. Stay locale-aware — don't hardcode `en_US`.

12h vs 24h: default to user-locale via `DateFormat.jm()`. Pakistan uses 12h; match the project's home screen convention.

**Do NOT include the end time** (Stitch shows `"Tomorrow, 3:00 PM - 5:00 PM"`; we display only start). Reasoning: end time is rarely useful to the customer at a glance (the booking duration is implied by service); the redundant text adds visual weight without informational value.

### §6.2 AWAITING SLA hint (only for AWAITING items)

Append `" · responding within ~15 min"` to the date string when `status == AWAITING`. Static copy in v1 — a live ticking countdown is deferred polish (see §13).

If you have time + appetite for a live countdown, derive it from `expiresAt` (passed in from the realtime envelope when present) and tick once per minute. Stop the timer when the card unmounts or status flips. Use a single `Stream.periodic` shared across cards if you build this; per-card `Timer.periodic` cleanup is risky.

---

## §7. State → render mapping

The screen consumes `customerBookingsListProvider` which is `AsyncValue<CustomerBookingsListState>`. **Every branch below MUST render something.** Do NOT use a default `Container()` or `SizedBox.shrink()` — silent screens are bugs.

Use `state.when()` or sealed-class pattern matching on `state.error` per CLAUDE.md. No `if (e is X)` chains.

| AsyncValue branch | Inner state | Render |
|---|---|---|
| `AsyncLoading` (initial, no previous data) | — | 4-card skeleton list with shimmer (§7.1) |
| `AsyncLoading` (with `state.value` from previous) | — | Render previous data unchanged + show `RefreshIndicator` active state |
| `AsyncData` | `items.isEmpty` AND `segment == upcoming` | `BookingsEmptyUpcoming` (§7.2) |
| `AsyncData` | `items.isEmpty` AND `segment == past` | `BookingsEmptyPast` (§7.3) |
| `AsyncData` | `items.isNotEmpty` AND `isStaleCache == false` | List of `BookingCard` |
| `AsyncData` | `items.isNotEmpty` AND `isStaleCache == true` | `BookingsOfflineBanner` pinned at top + list of cards (§7.4) |
| `AsyncData` | `items.isNotEmpty` AND `isLoadingMore == true` | List + footer spinner (§7.5) |
| `AsyncError(CustomerBookingsOfflineNoCache)` | — | `BookingsErrorState.offline` (§7.6) |
| `AsyncError(CustomerBookingsServerFailure)` | — | `BookingsErrorState.server` (§7.7) |
| `AsyncError(CustomerBookingsValidationFailure)` | — | Auto-call `refresh()` once. If it repeats → `BookingsErrorState.server` |
| `AsyncError(_)` (Unknown / catch-all) | — | `BookingsErrorState.unknown` (§7.8) |

### §7.1 Skeleton state (initial load)

`BookingCardSkeleton` widget. Dimensions match `BookingCard` exactly — same icon size, same row heights, same padding, same gap. The user sees no relayout when data lands.

- 4 skeletons stacked with the same `12pt` vertical gap.
- Shimmer: 1.2s cycle, `LinearGradient` from `surfaceContainerLow` → `surfaceContainerHigh` → `surfaceContainerLow`. If the project already uses the `shimmer` package, use that. Otherwise hand-roll with `AnimationController`.

### §7.2 Empty — Upcoming

Centered column, vertically centered in the available space:
- Illustration (un-centered ~200×200). If the project's home screen uses a specific illustration set, match it. Otherwise use unDraw or a simple Material Symbols `event_busy` at 96px in `outlineVariant`.
- Spacer `24`.
- Headline: `"No upcoming bookings"` in `h3`, `onSurface`.
- Spacer `8`.
- Body: `"Browse services to book a technician."` in `body-md`, `onSurfaceVariant`.
- Spacer `24`.
- Filled button: `"Browse services"` → `context.go('/home')`.

### §7.3 Empty — Past

Same vertical layout, **no CTA**:
- Illustration or `Material Symbols history` at 96px, `outlineVariant`.
- Headline: `"No past bookings"` in `h3`.
- Body: `"Your booking history will show up here."` in `body-md`, `onSurfaceVariant`.

### §7.4 Offline banner (cache fallback)

Pinned at top, between segmented control and list:
- Bg: `tertiaryFixedDim.withValues(alpha: 0.20)` (warning-tinted strip).
- Border-bottom: `1px tertiaryFixedDim.withValues(alpha: 0.40)`.
- Padding: `8` vertical, `16` horizontal.
- Row: `cloud_off_outlined` icon (16px, `onTertiaryFixed`) + `8` gap + text + spacer + Refresh icon button.
- Text: `"Offline · last updated {n} min ago"` where `n` = minutes since `state.value.cachedAt` (server-anchored if you have access; else local-clock — accept the small skew here, it's user-tolerable).
- Refresh icon button: `refresh` Material Symbol, calls `listNotifier.refresh()`.
- Animate-in: `SlideTransition` from top, 200ms ease-out.
- Animate-out: when `isStaleCache` flips to false, slide up + fade, 200ms ease-in.

### §7.5 Pagination footer

When `state.value.isLoadingMore == true`:
- Last item in `ListView.builder` is a `Center` with vertical padding `24`, containing a `CircularProgressIndicator(strokeWidth: 2)` at 24px.
- When `isLoadingMore` flips back to false, footer is removed (the next render).

### §7.6 Offline error state (no cache)

Centered:
- `Material Symbols cloud_off_outlined` 96px, `outline`.
- Headline: `"You're offline"` in `h3`.
- Body: `"Connect and try again."` in `body-md`, `onSurfaceVariant`.
- Filled button: `"Retry"` → `listNotifier.refresh()`.

### §7.7 Server error state

Centered:
- `Material Symbols error_outline` 96px, `outline` (NOT red — red icons read as crashes).
- Headline: `"Couldn't load your bookings"` in `h3`.
- Body: `"Something went wrong on our end. Please try again."` in `body-md`, `onSurfaceVariant`.
- Filled button: `"Retry"` → `listNotifier.refresh()`.

### §7.8 Unknown error state

Same as §7.7 with body text: `"Something went wrong. Please try again."` (per `UnknownCustomerBookingsFailure.message`).

---

## §8. Animations + polish (the "production-quality" budget)

### §8.1 Card press states
- `InkWell` ripple, default Material 3 behavior.
- Press scale: `Transform.scale(scale: 0.98)` while pressed (matches Stitch's `active:scale-[0.98]`).
- Haptic feedback on tap: `HapticFeedback.lightImpact()`.

### §8.2 Skeleton loader
Per §7.1. Dimensions MUST match the real card.

### §8.3 Realtime status change animation

The list notifier patches the item in place. The card needs to react visually. Two coupled animations:

1. **Card pulse**: 1s ease-in-out, container background fades `surfaceContainerLow` → `surfaceContainerLowest`. Triggers when `booking.status` changes between rebuilds.
2. **Pill morph**: `AnimatedSwitcher` around `BookingStatusPill` with `key: ValueKey(booking.ui.badgeText)`. Duration 250ms, fade transition. Pill text + tone change fades cleanly instead of snapping.

Implement (1) with a tiny `StatefulWidget` wrapper that captures `oldStatus` and runs an `AnimationController` when status diffs. Don't auto-scroll the list to the changed card.

### §8.4 Items moving segments (e.g., AWAITING → REJECTED while user is on Upcoming)

When the patched item's new status no longer matches the current segment's predicate (e.g., a `bookingRejected` event lands while user is on Upcoming), the item should **fade out from the current segment** (250ms opacity 1→0 + 50% height collapse). The user taps "Past" to find it. Don't auto-switch tabs.

The list notifier will keep the item in `items` until the next `refresh()` because the patch only flips status, not the inclusion predicate. To handle this gracefully: in the BookingCard, watch for `(segment == upcoming AND status in past statuses)` and animate the card out via an internal `AnimatedSize` + `AnimatedOpacity`. Once collapsed, return `SizedBox.shrink()`.

This is local widget-level filtering; doesn't touch the data layer.

### §8.5 Pull-to-refresh
- Material `RefreshIndicator`, default colors.
- Skip the haptic-on-engage in v1 (deferred polish).

### §8.6 Empty state illustrations
Match home screen if it has illustrations. Otherwise use Material Symbols at 96px in `outlineVariant`. Don't ship "TODO" placeholder text.

### §8.7 Hero animation on the service icon

Wrap the service icon in `Hero(tag: 'booking-icon-${item.id}', child: ...)`. The detail screen (next sprint) will use the same tag for a 24px → larger morph. Cheap groundwork now, big polish later.

---

## §9. File plan

Create under `frontend/lib/features/customer/bookings/presentation/`:

```
presentation/
  screens/
    customer_bookings_list_screen.dart         // The tab destination.
    (customer_booking_detail_screen.dart already exists as a stub — do NOT touch)
  widgets/
    booking_card.dart                           // Dumb card. ~180 lines incl. Cancelled treatment.
    booking_card_skeleton.dart                  // Shimmer skeleton, dimensions matching card.
    booking_status_pill.dart                    // Tone → token via BookingTonePalette.
    booking_tech_avatar.dart                    // 48px CircleAvatar with initials fallback.
    bookings_segmented_control.dart             // M3 SegmentedButton + count badges.
    bookings_empty_upcoming.dart                // Empty state with "Browse services" CTA.
    bookings_empty_past.dart                    // Empty state, no CTA.
    bookings_offline_banner.dart                // Amber strip for isStaleCache.
    bookings_error_state.dart                   // offline / server / unknown variants.
  utils/
    date_formatter.dart                          // Smart "Today / Tomorrow / In 30 min" helper.
    booking_tone_palette.dart                    // BookingUiTone → BookingTonePalette resolver.
```

Update existing files:

```
frontend/lib/features/customer/home/presentation/screens/home_screen.dart
  // Convert to IndexedStack shell. See §10.

frontend/lib/features/customer/home/presentation/providers/current_tab_notifier.dart
  // NEW — simple int state notifier for the active tab.

frontend/lib/core/routing/app_router.dart
  // Register GoRoute('/customer/bookings'). See §11.
```

The boot-hook providers (`customerBookingsListProvider`, `customerBookingsCountsProvider`) are **already registered** in `realtimeBootHooksProvider` — confirm and don't double-register.

---

## §10. Bottom-nav wiring — `IndexedStack` shell

`home_screen.dart` currently has a hardcoded `BottomNavigationBar` with `currentIndex: 0` and no `onTap`. Convert it.

### §10.1 New tab-state provider

`frontend/lib/features/customer/home/presentation/providers/current_tab_notifier.dart`:

```dart
@riverpod
class CurrentCustomerTab extends _$CurrentCustomerTab {
  @override
  int build() => 0;
  void set(int index) {
    if (state == index) return;
    state = index;
  }
}
```

Not `keepAlive` — scoped to the home screen mount.

### §10.2 Convert HomeScreen body to IndexedStack

```dart
final tab = ref.watch(currentCustomerTabProvider);

Scaffold(
  body: IndexedStack(
    index: tab,
    children: const [
      HomeFeed(),                      // Existing home content (extract from current build).
      CustomerBookingsListScreen(),    // The new screen.
      _MessagesPlaceholder(),          // Stub OK.
      _ProfilePlaceholder(),           // Stub OK.
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: tab,
    onTap: (i) => ref.read(currentCustomerTabProvider.notifier).set(i),
    items: const [...],  // Same items as today.
    // Style per §3.7.
  ),
);
```

`IndexedStack` keeps every tab mounted. Scroll position + Riverpod state survive switches — the entire reason we picked this pattern.

---

## §11. GoRoute registration

In `app_router.dart`:

```dart
GoRoute(
  path: '/customer/bookings',
  builder: (context, state) => const CustomerBookingsListScreen(),
),
```

This route is mainly for **deep linking** (FCM tap on "View your bookings"). The tab UX uses `IndexedStack`, not navigation. The route exists so an external link or notification can land on the screen.

---

## §12. Testing requirements

Per CLAUDE.md frontend testing rules — `flutter_test` + `mocktail`.

### §12.1 Test files

```
test/features/customer/bookings/presentation/
  widgets/
    booking_card_test.dart
    booking_card_skeleton_test.dart
    booking_status_pill_test.dart
    booking_tech_avatar_test.dart
    bookings_segmented_control_test.dart
    bookings_empty_upcoming_test.dart
    bookings_empty_past_test.dart
    bookings_offline_banner_test.dart
    bookings_error_state_test.dart
  screens/
    customer_bookings_list_screen_test.dart
  utils/
    date_formatter_test.dart
    booking_tone_palette_test.dart
```

### §12.2 Coverage targets

**`booking_card_test.dart`** — render permutations:
- 7 render tests, one per status row in §5.8 (AWAITING / CONFIRMED / COMPLETED / CANCELLED / REJECTED-declined / REJECTED-timeout / PENDING) using hand-rolled Freezed entities.
- `addressLabel == null` hides address row.
- `profile_picture_url == null` shows initials fallback in avatar.
- `price.context == ""` hides the price-context icon + text.
- Tap fires `context.push('/customer/booking/{id}')` (use `MockNavigatorObserver` or `GoRouter` test harness).
- Hero tag is `'booking-icon-${id}'`.
- Cancelled visual treatment: container opacity 0.85, address text decoration is `lineThrough`.

**`booking_status_pill_test.dart`**:
- Each `BookingUiTone` produces the expected bg/fg pair from `BookingTonePalette`.
- `unknown` falls back to neutral.

**`booking_tech_avatar_test.dart`**:
- Renders `NetworkImage` when URL is non-null.
- Renders initials fallback when URL is null.
- Handles single-name (no last name) gracefully.
- Handles all-whitespace name (returns blank avatar bg, no crash).

**`bookings_segmented_control_test.dart`**:
- Tapping a segment calls `set()` on `selectedSegmentProvider`.
- Count badge renders when `customerBookingsCountsProvider` is `AsyncData`.
- No badge when loading or error.
- Active vs inactive styling: bg + text color + shadow.

**`bookings_empty_upcoming_test.dart`** / **`bookings_empty_past_test.dart`**:
- Per-segment copy.
- Upcoming: "Browse services" CTA fires `context.go('/home')`.
- Past: no CTA.

**`bookings_offline_banner_test.dart`**:
- Renders text containing the minute-delta from `cachedAt`.
- Refresh icon button calls `listNotifier.refresh()`.
- Slide-in animation hooked up.

**`bookings_error_state_test.dart`**:
- Three variants: offline / server / unknown.
- Retry button fires the correct callback.

**`customer_bookings_list_screen_test.dart`** (state → render):
- AsyncLoading → 4 skeleton cards.
- AsyncData empty + upcoming → `BookingsEmptyUpcoming`.
- AsyncData empty + past → `BookingsEmptyPast`.
- AsyncData with items → list of `BookingCard`.
- AsyncData with `isStaleCache=true` → offline banner + list.
- AsyncData with `isLoadingMore=true` → list + footer spinner.
- AsyncError(`CustomerBookingsOfflineNoCache`) → offline error state.
- AsyncError(`CustomerBookingsServerFailure`) → server error state.
- AsyncError(`UnknownCustomerBookingsFailure`) → unknown error state.
- Pull-to-refresh triggers both list and counts refresh in parallel.
- Scrolling near end triggers `loadMore()` (verify with a `ScrollController`).

**`date_formatter_test.dart`**:
- Each row in §6.1's lookup table.
- Anchor-on-server-now behavior (provide a fake `serverNow`; assert no leakage of `DateTime.now()`).
- AWAITING SLA hint appended.
- `intl` locale handling (en_US + one non-US).

**`booking_tone_palette_test.dart`**:
- Each tone resolves to expected `(bg, fg)` against a fake `ColorScheme`.

### §12.3 Manual QA checklist (per CLAUDE.md "test the UI in a browser before declaring complete")
- [ ] Pull-to-refresh works in both segments
- [ ] Switching segments preserves scroll position in the *other* segment
- [ ] Card tap navigates to the existing detail-screen stub
- [ ] Realtime patch animation fires when a `job_accepted` is simulated via `SystemEventNotifier.processEvent`
- [ ] Items moving segments fade out gracefully (don't snap-disappear)
- [ ] Offline banner appears when network is killed and a cached page is served
- [ ] Skeleton dimensions match real card dimensions exactly (no relayout flash on data arrival)
- [ ] Bottom-nav state preservation: scroll Upcoming, switch to Profile, switch back — Upcoming is where you left it
- [ ] Empty states render correctly per segment
- [ ] All 7 status renderings look right
- [ ] Cancelled visual treatment: opacity decay + line-through reads as "cancelled" without being aggressive
- [ ] Avatar initials fallback works for users without profile pics
- [ ] Long tech names + addresses ellipsize gracefully
- [ ] Locale switch (set device to non-English) doesn't crash date formatter

---

## §13. Anti-patterns — what NOT to take from Stitch

Stitch is **visual reference for tokens, not for code or copy**. The two designs have specific issues you must override:

| Stitch shows | Our spec says | Reason |
|---|---|---|
| Pill text `PENDING` for AWAITING | `Awaiting tech` (server-emitted) | Wire contract — server is source of truth for copy |
| Pill text in error-container tone for `Cancelled` | Use **neutral** tone | API §1.7 canonical table |
| Headline `"Awaiting confirmation from M. Usman"` | `"Waiting for M. Usman to confirm"` | Wire contract |
| Headline `"Cancelled booking with Usman Ali"` | `"You cancelled this booking"` | Wire contract |
| Price context `Estimated` | Use server's `price.context` value | `Estimated` does not exist on the wire |
| **No price** on Cancelled card | Render `price.uiLabel` always (with opacity 0.7) | Info preservation; user might still owe inspection fee |
| Two different card layouts (Upcoming vs Past) | ONE `BookingCard` widget, status-driven decoration only | Component reuse; consistency |
| Empty AppBar title on Past (Stitch bug: `<br>` tag) | Title `"My Bookings"` always | Real bug in Stitch HTML |
| Date format `"Tomorrow, 3:00 PM - 5:00 PM"` (with end time) | Start time only — `"Tomorrow, 3:00 PM"` | End time is rarely useful at a glance |
| Date format `"Oct 12, 2023 at 10:00 AM"` (with year + "at") | Smart formatter from §6.1 | Consistent across segments |
| No service SVG icon — replaced by avatar entirely | Both — service icon (24px) at top-left header AND tech avatar (48px) in headline row | Honour `IconAssets.path()` convention; don't lose service identifier |
| Service name as ONLY identifier (small uppercase, top) | Same — but pair with the 24px service icon | Combine both project conventions |

If you find yourself recreating any of the above from the Stitch HTML — **stop and re-read this section.**

---

## §14. Production quality bar

The bar:

- **Smooth scrolling** — no jank when realtime patches land. Wrap `BookingCard` in `RepaintBoundary` if profiling shows raster cost.
- **Instant tab switches** — `IndexedStack` keeps tabs mounted. Don't add `Future.delayed` "loading" theatrics.
- **Skeleton matches card dims exactly** — no jarring relayout when data lands.
- **Empty + error states feel intentional** — illustrations + clear copy + clear CTA. Not "TODO" placeholders.
- **Offline UX is honest** — the banner says "last updated 8 min ago", not "you're offline" with stale data behind it. The user knows what they're looking at.
- **Realtime is invisible** — the user sees a card silently change from "Awaiting tech" to "Confirmed with Ahmed Khan" with a soft pulse. They don't see a spinner. They don't see a snackbar. The data just updates.
- **Animations are subtle** — 1s pulse, 250ms morph. Not 500ms slides. Not bounce curves. The product feels "calm and competent", not "look at our animations".
- **Typography hierarchy is consistent** — every text uses the M3 token from §3.2. No ad-hoc font sizes.
- **No copy says "Something went wrong" as the only error message** — be specific: "You're offline" / "Couldn't load your bookings" / "This filter isn't valid". Each error has distinct cause and copy.
- **Cancelled treatment reads correctly** — opacity + line-through tells the user "this is past and was not completed" without screaming. Not a red banner. Not a strikethrough on the headline (only the address).
- **The UI never goes silent on any state** — every AsyncValue branch from §7 renders something. No `SizedBox.shrink()` defaults.

What "production" does NOT mean for this sprint:

- ✗ Pixel-perfect Figma compliance (we don't have Figma; Stitch is the closest reference).
- ✗ Multiple themes / dark mode polish (lean on the project's existing theme; don't redesign).
- ✗ Complex transitions between screens (Hero on the service icon is the only one that matters).
- ✗ Custom-painted decorations.
- ✗ Sound effects on state changes.
- ✗ Live SLA countdown for AWAITING (static "responding within ~15 min" is fine for v1).
- ✗ Pull-to-refresh haptic engage (deferred; default `RefreshIndicator` is fine).

---

## §15. Resolved decisions (no longer open questions)

The prior session_4 had open questions in §13. Now resolved:

| Question | Resolution |
|---|---|
| Status pill leading-dot indicator (●) | **Skip.** Stitch doesn't use one. |
| Pull-to-refresh haptic engage | **Skip in v1.** Default `RefreshIndicator` is fine. |
| AWAITING SLA hint — live countdown vs static | **Static** for v1: `" · responding within ~15 min"`. Live countdown is documented as polish. |
| Empty state CTA on Upcoming → `/home` or `/search` | **`/home`.** Matches existing project navigation pattern; users see service browse. |
| Counts badge format | **`Upcoming · 1`** with bullet separator (Stitch convention). |
| Service icon vs tech avatar — which wins? | **Both.** Service icon as 24px decoration in top-left header; tech avatar as 48px in headline row. Honours both project conventions. |

---

## §16. Definition of done

- [ ] All files in §9 created and passing `dart analyze` with 0 errors.
- [ ] Theme integration: `BookingTonePalette` reads from the project's existing `ColorScheme` — does NOT duplicate Color literals from §3.1.
- [ ] All widget tests in §12 written and passing (proposed first per CLAUDE.md, then written after approval).
- [ ] Manual QA checklist in §12.3 ticked.
- [ ] `home_screen.dart` converted to `IndexedStack` shell with `currentTabProvider`.
- [ ] `/customer/bookings` GoRoute registered.
- [ ] All 7 statuses render correctly (visual QA + tests).
- [ ] Realtime patch animation fires correctly (manual sim via `SystemEventNotifier.processEvent`).
- [ ] flag #27 marked `~~strikethrough~~ ✅ Resolved (date)` with a "What changed" summary.
- [ ] `CUSTOMER_BOOKINGS_FEATURE.md` updated: `presentation/screens` and `presentation/widgets` flipped from ⏳ pending to ✅ shipped, file inventory added.
- [ ] No regressions in existing widget tests (`flutter test` on the full suite, not just bookings).

---

## §17. The dumb-UI contract

The data layer ships with **209 tests** and a **canonical status → ui table** in `CUSTOMER_BOOKINGS_API.md` §1.7. That table is mirrored in `BookingEventPatchMapper`. Your widget MUST defer to that contract — never recompute headline copy or badge text from raw `status`.

If you find yourself writing:

```dart
// ❌ NEVER
String headline = booking.status == BookingStatus.confirmed
    ? "Confirmed with ${booking.technician.displayName}"
    : "Waiting for ${booking.technician.displayName}";
```

stop. Read `booking.ui.headline`. The whole point of the data sprint was to make this widget dumb.

If a copy change is needed, it goes into `_resolve_ui_block` on the backend AND `BookingEventPatchMapper` on the frontend, in lockstep. Not in a widget.

The same applies to:
- Status pill text → `booking.ui.badgeText`
- Status pill tone → `booking.ui.badgeTone`
- Price label → `booking.price.uiLabel`
- Price context → `booking.price.context`
- Address line → `booking.addressLabel`

**The Stitch designs violate this contract in five places** (§13). Don't recreate the violations.

---

## Appendix A — Stitch screens for visual reference

Use these for **visual tokens only** (color, type, chrome, pill geometry, spacing). Do NOT copy code or copy text.

| Screen | Use for |
|---|---|
| `projects/3379302216315648259/screens/153eda9c56854c0c865e202257e1e7c8` ("My Bookings - Upcoming (Polished)") | Card chrome, segmented control style, header structure, avatar size, primary price treatment |
| `projects/3379302216315648259/screens/873809652fe94ae2b2f9be0ffefd3f32` ("My Bookings - Past (Polished)") | Cancelled visual decay (opacity + line-through), past-section card structure |

Both screens fetched via `mcp__stitch__get_screen` if you need them again.

---

## Appendix B — Reference implementations in this codebase

When stuck, read in this order:

1. `frontend/lib/features/customer/home/presentation/screens/home_screen.dart` — tab shell scaffolding (currently broken; you'll fix it).
2. `frontend/lib/features/technician/incoming_job_requests/presentation/widgets/incoming_job_card.dart` — card layout precedent, animation timing.
3. `frontend/lib/features/customer/home/presentation/widgets/home_skeleton_loader.dart` — skeleton pattern.
4. `frontend/lib/features/customer/discovery/presentation/screens/discovery_results_screen.dart` — list-style screen with infinite scroll.
5. `frontend/lib/core/routing/app_router.dart` — route registration site.
6. `frontend/lib/core/theme/` — design tokens. **Use these — don't duplicate Color literals from §3.1 if the theme already exposes them.**

For state management:

- `frontend/lib/features/customer/discovery/presentation/providers/discovery_notifier.dart` — `state.value` access pattern, `copyWithPrevious` usage.
- `frontend/lib/features/customer/home/presentation/providers/home_notifier.dart` — async build + refresh pattern.

Read them. Match their style. Don't reinvent.

---

## Appendix C — Quick reference card (TL;DR for the implementer)

When you start coding, this is what you need at a glance:

**Source-of-truth precedence**: API contract → this file → Stitch (tokens only) → project conventions.

**One widget**: `BookingCard` for both segments. Differences = pill + headline + Cancelled treatment. Same layout, same chrome, same spacing.

**Five fields are server-rendered** — never recompute:
- `ui.badgeText`, `ui.badgeTone`, `ui.headline`
- `price.uiLabel`, `price.context`

**Three fields nullable** — handle gracefully:
- `addressLabel == null` → hide row
- `profile_picture_url == null` → initials fallback
- `price.context == ""` → hide context line

**Eleven render branches** — every one MUST render something visible (§7).

**Seven status permutations** to test (§5.8).

**One animation** that's load-bearing: 1s card pulse + 250ms pill morph on realtime patch.

**Stitch lies in five specific places** — see §13. Override them.

When in doubt: API contract wins for copy, this file wins for behavior, Stitch wins for visual tokens. Never the other way around.
