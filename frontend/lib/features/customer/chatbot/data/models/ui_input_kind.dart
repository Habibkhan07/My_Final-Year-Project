/// Wire enum for the `ui_input_kind` discriminator returned by every
/// turn response.
///
/// The data source parses this from a string (defensive default to
/// [unknown] on rollout drift); the mapper translates it into the
/// appropriate `UiDirective` subclass alongside `ui_form_schema` /
/// `ui_hint` / `bot_message` / `is_closed` / `output_refs`.
///
/// Source-of-truth wire values: `backend/chatbot/services/ports.py`
/// `TurnResult.ui_input_kind`.
enum UiInputKind {
  text,
  form,
  attachment,
  none,
  unknown;

  static UiInputKind fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'text':
        return UiInputKind.text;
      case 'form':
        return UiInputKind.form;
      case 'attachment':
        return UiInputKind.attachment;
      case 'none':
      case '':
        return UiInputKind.none;
      default:
        return UiInputKind.unknown;
    }
  }
}
