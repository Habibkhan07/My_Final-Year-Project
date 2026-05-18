import 'package:flutter/material.dart';

import '../_palette/orchestrator_palette.dart';

/// Single-line-ish optional text field for free-form comments.
///
/// Owns its own [TextEditingController] so the user's typing doesn't
/// thrash the parent notifier on every keystroke — we only push the
/// final value up on submit (via the parent's `onChanged` debouncer)
/// OR on blur. For viva-scope we just push on every change; debouncing
/// is an optimisation we can layer in later.
///
/// `maxLength=500` matches the backend's `ReviewSubmitSerializer.text`
/// max_length. Counter is shown only when the user is within 50 chars
/// of the limit so the form doesn't feel like a survey.
class OptionalCommentField extends StatefulWidget {
  const OptionalCommentField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<OptionalCommentField> createState() => _OptionalCommentFieldState();
}

class _OptionalCommentFieldState extends State<OptionalCommentField> {
  late final TextEditingController _controller;
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _length = widget.initialText.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showCounter = _length >= 450; // last 50 chars
    return TextField(
      controller: _controller,
      maxLength: 500,
      maxLines: 3,
      minLines: 2,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 14, height: 1.4),
      decoration: InputDecoration(
        hintText: 'Anything else? (optional)',
        hintStyle: const TextStyle(
          color: OrchestratorPalette.inkTertiary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        counterText: showCounter ? '$_length / 500' : '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: OrchestratorPalette.brandPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() => _length = value.length);
        widget.onChanged(value);
      },
    );
  }
}
