/// Phases the backend state machine moves through during a chatbot
/// conversation. The UI **does not branch on this** — it renders
/// `UiDirective` from each turn-response and is otherwise blind to
/// where in the flow it sits.
///
/// Kept for two reasons only:
///
///   * Transcript audit: every [chat_message.ChatMessage] carries the
///     phase it was written under so a future "explain my dispute"
///     screen can group by phase.
///
///   * Telemetry: logging which phase a network failure happened in
///     helps diagnose backend rollout issues without leaking content.
///
/// The wire shape is a free-form string per backend contract — new
/// phases ship from the backend without a Flutter release. [unknown]
/// is the mapper's defensive default so unrecognised wire values do
/// not throw at the boundary.
enum ChatPhase {
  understand,
  evidence,
  payout,
  confirm,
  closed,
  unknown;

  /// Backend wire string this case corresponds to. Lossy for
  /// [unknown] — that case maps back to an empty string because we
  /// never round-trip an unknown value to the server.
  String get wireValue {
    switch (this) {
      case ChatPhase.understand:
        return 'UNDERSTAND';
      case ChatPhase.evidence:
        return 'EVIDENCE';
      case ChatPhase.payout:
        return 'PAYOUT';
      case ChatPhase.confirm:
        return 'CONFIRM';
      case ChatPhase.closed:
        return 'CLOSED';
      case ChatPhase.unknown:
        return '';
    }
  }

  /// Forgiving wire-string parser. Unknown / empty values fold to
  /// [unknown] so the mapper never throws when the backend adds a
  /// new phase. Case-insensitive.
  static ChatPhase fromWire(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'UNDERSTAND':
        return ChatPhase.understand;
      case 'EVIDENCE':
        return ChatPhase.evidence;
      case 'PAYOUT':
        return ChatPhase.payout;
      case 'CONFIRM':
        return ChatPhase.confirm;
      case 'CLOSED':
        return ChatPhase.closed;
      default:
        return ChatPhase.unknown;
    }
  }
}
