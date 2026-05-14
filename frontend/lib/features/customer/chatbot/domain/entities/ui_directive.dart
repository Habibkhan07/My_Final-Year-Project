// Polymorphic dispatch for the chatbot input composer. The screen
// holds the latest [UiDirective] from the server-driven state machine
// and the input renderer switches on the subclass — adding a new
// directive (e.g. a future VoiceDirective) is one subclass + one
// composer widget, and the Dart compiler flags every switch we miss.
//
// Wire-shape spec: backend sends `ui_input_kind` plus optional
// `ui_form_schema`, `ui_hint`, `bot_message`, `is_closed`,
// `output_refs`. The mapper turns those into one of the subclasses
// below — see `chatbot_mapper.dart`.
import 'form_schema.dart';
import 'output_refs.dart';

/// Sealed root. The renderer's switch on a [UiDirective] is exhaustive
/// by Dart compiler check — never default-cased.
sealed class UiDirective {
  /// The bot's most recent message to display **above** the composer.
  /// Empty string is valid (e.g. on TerminalDirective, where the
  /// closing card carries its own copy and there is no bubble).
  final String botMessage;

  /// One-line placeholder / instruction the composer shows
  /// (e.g. "Tell me what happened", "Up to 10 photos"). Empty when
  /// the composer doesn't need one (terminal directive).
  final String hint;

  const UiDirective({required this.botMessage, required this.hint});
}

/// Free-text composer. The default phase shape.
final class TextDirective extends UiDirective {
  const TextDirective({required super.botMessage, required super.hint});
}

/// Server-driven dynamic form. [persistDraft] is `false` for PAYOUT
/// (IBAN is PII — see CLAUDE.md §`Local Storage & Caching`); the draft
/// notifier becomes a no-op when this is false so IBAN never reaches
/// SharedPreferences.
final class FormDirective extends UiDirective {
  final FormSchema schema;
  final bool persistDraft;

  const FormDirective({
    required this.schema,
    required this.persistDraft,
    required super.botMessage,
    required super.hint,
  });
}

/// Attachment grid + camera/gallery picker + a "Done" button.
/// [currentCount] is the count the server reported at the last turn;
/// the composer also reads the live count from its own upload
/// notifier so a successful upload reflects before the next turn.
/// [maxAllowed] mirrors the backend `CHATBOT_MAX_ATTACHMENTS` setting
/// (default 10).
final class AttachmentDirective extends UiDirective {
  final int currentCount;
  final int maxAllowed;

  const AttachmentDirective({
    required this.currentCount,
    required this.maxAllowed,
    required super.botMessage,
    required super.hint,
  });
}

/// Conversation is closed. The renderer mounts the closing card with
/// the ticket id + SLA string from [refs]; no composer is shown.
final class TerminalDirective extends UiDirective {
  final OutputRefs refs;

  const TerminalDirective({required this.refs})
    : super(botMessage: '', hint: '');
}
