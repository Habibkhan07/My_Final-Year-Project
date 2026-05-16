import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/profile_failure.dart';
import '../providers/profile_notifier.dart';

/// Pushed from the profile tab's header card.
///
/// Pre-fills both first and last name from the cached profile. Save
/// submits both fields (backend serializer requires both); even if the
/// user only edited one, the unchanged one round-trips back unchanged.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _mutedText = Color(0xFF727785);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _firstNameServerError;
  String? _lastNameServerError;
  bool _initialised = false;
  // Local saving state. We track this in the screen rather than via
  // `profileProvider.isLoading` because the notifier intentionally
  // does NOT transition through AsyncLoading during the PATCH — that
  // would blank the profile tab if the save fails. The screen owns
  // its own in-flight indicator and reads the call outcome directly.
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _hydrateFromState() {
    if (_initialised) return;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _initialised = true;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _firstNameServerError = null;
      _lastNameServerError = null;
    });

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    final result = await ref.read(profileProvider.notifier).updateName(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _brandBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
      return;
    }

    final error = result.error;
    if (error is ProfileServerFailure) {
      final firstErr = (error.errors['first_name'] as List?)?.firstOrNull;
      final lastErr = (error.errors['last_name'] as List?)?.firstOrNull;
      setState(() {
        _firstNameServerError = firstErr?.toString();
        _lastNameServerError = lastErr?.toString();
      });
    }

    String message = 'Could not save changes.';
    if (error is ProfileFailure) message = error.message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    _hydrateFromState();

    // Two related but distinct flags:
    //   * `_saving` — PATCH is in flight. Shows spinner inside the
    //     Save button (visual signal that work is happening).
    //   * `disabled` — covers `_saving` PLUS "initial profile load
    //     hasn't completed", because submitting before the form
    //     hydrates would PATCH empty strings.
    final disabled = _saving || !profileAsync.hasValue;
    final phone = profileAsync.value?.phone ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Edit profile',
          style: TextStyle(
            color: _titleText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleText),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Phone number'),
                const SizedBox(height: 6),
                _PhoneReadOnlyTile(phone: phone),
                const SizedBox(height: 4),
                const Text(
                  'Phone changes require a re-verification (coming soon).',
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('First name'),
                const SizedBox(height: 6),
                _NameField(
                  controller: _firstNameController,
                  hint: 'e.g. Ali',
                  serverError: _firstNameServerError,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'First name is required.'
                      : null,
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Last name'),
                const SizedBox(height: 6),
                _NameField(
                  controller: _lastNameController,
                  hint: 'e.g. Raza',
                  serverError: _lastNameServerError,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Last name is required.'
                      : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: disabled ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _brandBlue.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: _brandBlue.withValues(alpha: 0.4),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Color(0xFF424753),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.serverError,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 150,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF151C24),
        fontWeight: FontWeight.w600,
      ),
      validator: (v) => serverError ?? validator(v),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(color: Color(0xFF727785)),
        filled: true,
        fillColor: const Color(0xFF0051AE).withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0051AE), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }
}

class _PhoneReadOnlyTile extends StatelessWidget {
  const _PhoneReadOnlyTile({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: Color(0xFF727785)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              phone.isEmpty ? '—' : phone,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF424753),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
