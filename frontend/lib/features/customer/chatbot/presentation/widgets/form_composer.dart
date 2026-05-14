import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_session.dart';
import '../../domain/entities/form_schema.dart';
import '../../domain/entities/ui_directive.dart';
import '../../domain/failures/chatbot_failure.dart';
import '../notifiers/chatbot_session_notifier.dart';
import '../utils/chatbot_palette.dart';

/// Dynamic form composer for [FormDirective] phases (PAYOUT is the
/// only one in dispute v1; the BANK_FORM_SCHEMA — bank name, account
/// title, IBAN — is what gets mounted).
///
/// **PII discipline.** [FormDirective.persistDraft] is `false` for
/// PAYOUT. This composer **never** writes to [DraftNotifier]; the
/// field values live only in the local [TextEditingController]
/// instances and the in-flight POST body. IBAN, account title, and
/// bank name never reach SharedPreferences. See plan §11 PII table.
///
/// **Validation pipeline.**
///   * Client-side: each field's [FormFieldSpec.validationPattern]
///     (when present) is compiled into a `RegExp` and used as an
///     **advisory** validator — the field's `errorText` shows the
///     regex mismatch in red. Advisory because the backend re-validates
///     on submit regardless.
///   * Server-side: on a [FormValidationFailure] response, the
///     `fieldErrors` map (keyed by field name) is captured via
///     `ref.listen` on the session provider and painted as
///     `errorText` per field, overriding the client-side advisory.
///
/// **Submit flow.**
///   1. Form's [FormState.validate] runs the client-side validators.
///   2. If client-valid, calls `sessionNotifier.submitForm(values)`.
///   3. If the call fails with [FormValidationFailure], the captured
///      `_serverErrors` map fills `errorText`s.
///   4. If the call fails with any other [ChatbotFailure], the
///      screen-level `ref.listen` handles it (SnackBar / dialog).
///   5. On success, the directive transitions to the next phase and
///      the input renderer mounts a different composer; this widget
///      simply unmounts.
class FormComposer extends ConsumerStatefulWidget {
  final String personaKey;
  final int bookingId;
  final ChatSession session;
  final FormDirective directive;

  const FormComposer({
    super.key,
    required this.personaKey,
    required this.bookingId,
    required this.session,
    required this.directive,
  });

  @override
  ConsumerState<FormComposer> createState() => _FormComposerState();
}

class _FormComposerState extends ConsumerState<FormComposer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  Map<String, String> _serverErrors = const {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.directive.schema.fields)
        f.name: TextEditingController(),
    };
  }

  @override
  void didUpdateWidget(covariant FormComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Schema can change between turns if a future persona iterates.
    // Add controllers for new fields; leave existing controllers alone
    // so in-flight text isn't dropped on a no-op directive rebuild.
    for (final f in widget.directive.schema.fields) {
      _controllers.putIfAbsent(f.name, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Pull a `FormValidationFailure` (if any) out of the latest error
  /// frame and replay its `fieldErrors` map into [_serverErrors].
  void _captureServerErrors(Object? error) {
    if (error is FormValidationFailure) {
      final flat = <String, String>{};
      error.fieldErrors.forEach((field, messages) {
        if (messages.isNotEmpty) flat[field] = messages.first;
      });
      setState(() => _serverErrors = flat);
    }
  }

  String? _validateField(FormFieldSpec spec, String? value) {
    // Server error wins when present — it's the authoritative one.
    final serverMessage = _serverErrors[spec.name];
    if (serverMessage != null) return serverMessage;
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Required';
    final pattern = spec.validationPattern;
    if (pattern == null) return null;
    try {
      final re = RegExp(pattern);
      if (!re.hasMatch(v)) return 'Format looks off';
    } on FormatException {
      // Malformed regex from the wire — fail open: client-side
      // validation is advisory anyway; the server will re-check.
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    // Clear stale server errors before the new attempt so a re-submit
    // with a corrected value doesn't keep the old red message.
    setState(() => _serverErrors = const {});
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _submitting = true);

    final values = <String, dynamic>{
      for (final f in widget.directive.schema.fields)
        f.name: _controllers[f.name]!.text.trim(),
    };

    await ref
        .read(
          chatbotSessionProvider(
            personaKey: widget.personaKey,
            bookingId: widget.bookingId,
          ).notifier,
        )
        .submitForm(values);

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    // Capture any new server-side validation errors as the session
    // state transitions through error frames.
    ref.listen(
      chatbotSessionProvider(
        personaKey: widget.personaKey,
        bookingId: widget.bookingId,
      ),
      (prev, next) => _captureServerErrors(next.error),
    );

    final fields = widget.directive.schema.fields;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ChatbotPalette.composerSurface,
          boxShadow: ChatbotPalette.composerSoftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.directive.botMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.directive.botMessage,
                    style: TextStyle(
                      color: ChatbotPalette.systemInk,
                      fontSize: 13,
                    ),
                  ),
                ),
              ...fields.map(_buildField),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChatbotPalette.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(FormFieldSpec spec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[spec.name],
        enabled: !_submitting,
        validator: (value) => _validateField(spec, value),
        decoration: InputDecoration(
          labelText: spec.label,
          isDense: true,
          filled: true,
          fillColor: ChatbotPalette.brandPrimaryTint06,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: ChatbotPalette.brandPrimary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
