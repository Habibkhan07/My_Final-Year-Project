import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../customer/bookings/domain/entities/booking_ui_tone.dart';

part 'booking_ui_block.freezed.dart';

/// The server-resolved UI block for the orchestrator screen.
///
/// Per the dumb-UI principle (CLAUDE.md): every piece of copy + every
/// button label + every slot toggle flows from this block. The screen
/// never branches on raw [BookingStatus] for display content — only the
/// body slot dispatches the specialized widget per status.
///
/// Wire shape mirrors `backend/bookings/selectors/orchestrator_ui.py`
/// `resolve_orchestrator_ui()`. New backend fields added there must be
/// reflected here AND in the mapper.
@freezed
abstract class BookingUiBlock with _$BookingUiBlock {
  const factory BookingUiBlock({
    /// Top-of-screen status badge text. e.g. "Confirmed", "On the way".
    required String statusLabel,

    /// Prose for the body slot. May be empty for terminal states where
    /// the body is purely visual (timeline + receipt summary).
    required String bodyText,

    /// Call-to-action button rendered at the bottom. Null when the user's
    /// role has no actionable verb at this status (e.g. customer waiting
    /// for tech to mark arrival).
    BookingUiAction? primaryAction,

    /// Secondary actions rendered as text buttons above the primary.
    /// Order is server-controlled; widgets render verbatim.
    @Default([]) List<BookingUiAction> secondaryActions,

    /// Whether to render the live-tracking widget (session 4 fills in).
    /// Currently only true for EN_ROUTE / ARRIVED on customer view.
    required bool showTracking,

    /// Whether to render the quote line-item card.
    required bool showQuoteCard,

    /// Whether to surface the "Open dispute" button. Customer-side after
    /// IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW per
    /// `bookings/services/orchestrator.open_dispute` validation.
    required bool showDisputeButton,

    /// Background tint for the header slot. Maps to a design token in
    /// the widget — never to a literal color in code.
    required BookingUiTone tone,
  }) = _BookingUiBlock;
}

/// A button the screen renders verbatim. The [endpoint] string is the
/// backend-relative path (NOT including `/api/`) and the [method] is the
/// HTTP verb. The button widget classifies actions by endpoint suffix
/// to decide direct-POST vs. confirm-sheet behavior — see
/// `BookingOrchestratorActionButton._classify`.
@freezed
abstract class BookingUiAction with _$BookingUiAction {
  const factory BookingUiAction({
    required String label,
    required String endpoint,
    required String method,
    BookingUiActionStyle? style,
  }) = _BookingUiAction;
}

/// Visual style hint from the server. The widget picks the design token;
/// `unknown` falls back to the neutral style.
enum BookingUiActionStyle {
  primary,
  destructive,
  neutral,
  unknown;

  static BookingUiActionStyle fromWire(String? raw) => switch (raw) {
    'primary' => BookingUiActionStyle.primary,
    'destructive' => BookingUiActionStyle.destructive,
    'neutral' => BookingUiActionStyle.neutral,
    _ => BookingUiActionStyle.unknown,
  };
}
