// Server-driven schema for the dynamic PAYOUT form (and any future
// persona's form-phase). The widget layer reads this and builds
// TextFormFields with labels, hint text, validation regex.
// Wire spec: `backend/chatbot/api/CHATBOT_API.md` §`ui_form_schema`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_schema.freezed.dart';

/// Kind of input control the renderer should mount for a single field.
/// Today only [text] ships — the IBAN field uses a regex `validation`
/// block on top of the text input. Future kinds (e.g. `select`,
/// `phone`) get added here and the form composer's switch becomes
/// exhaustive-by-compiler.
enum FormFieldKind {
  text,
  unknown;

  static FormFieldKind fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'text':
        return FormFieldKind.text;
      default:
        return FormFieldKind.unknown;
    }
  }
}

/// One field in a server-driven form.
///
/// [validationPattern] is the raw regex string (e.g.
/// `^PK\d{2}[A-Z]{4}\d{16}$` for IBAN). Null when the server attached
/// no pattern. Client-side validation is **advisory only** — the
/// backend re-validates on submit and any mismatch comes back as a
/// `FormValidationFailure` with field-level errors.
@freezed
abstract class FormFieldSpec with _$FormFieldSpec {
  const factory FormFieldSpec({
    required String name,
    required String label,
    required FormFieldKind kind,
    String? validationPattern,
  }) = _FormFieldSpec;
}

/// The full server-driven form schema for a single turn. Ordered —
/// renderer mounts fields in [fields] order top-to-bottom.
@freezed
abstract class FormSchema with _$FormSchema {
  const factory FormSchema({
    required List<FormFieldSpec> fields,
  }) = _FormSchema;
}
