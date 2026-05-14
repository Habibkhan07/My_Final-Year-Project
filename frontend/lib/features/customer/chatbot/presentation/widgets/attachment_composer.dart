import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/chat_session.dart';
import '../../domain/entities/ui_directive.dart';
import '../notifiers/attachment_upload_notifier.dart';
import '../notifiers/chatbot_session_notifier.dart';
import '../utils/chatbot_palette.dart';

/// Attachment composer for the EVIDENCE phase.
///
/// **Visual layout:** a 3-column grid of thumbnails for already-picked
/// images, plus a brand-blue "+" tile at the end (disabled when count
/// is at `maxAllowed`). A "Done" button below advances the persona.
///
/// **Upload contract.**
///   1. User picks an image (camera or gallery) → returns an [XFile].
///   2. Composer reads the bytes once via `XFile.readAsBytes()` (the
///      only cross-platform read — on web `XFile.path` is a `blob:`
///      URL with no real File backing) and stores them in a local
///      `_PickedItem` keyed by a synthetic token.
///   3. Composer calls `attachmentUploadNotifier.markStart(token)` →
///      session notifier's `uploadAttachment(filename, bytes)` →
///      `markEnd(token)`. Per-tile spinner reads
///      `state.contains(token)`.
///   4. On success, `directive.currentCount` updates on the next turn;
///      between turns, this widget keeps a local "uploaded since last
///      directive" counter so the "X of Y" display stays consistent
///      without a directive refresh.
///   5. Errors ([AttachmentTooLargeFailure],
///      [AttachmentCountExceededFailure]) surface via the screen-level
///      `ref.listen` SnackBar. The failed _PickedItem is removed from
///      the local list so the grid doesn't keep a broken thumbnail.
///
/// **Done flow.** Tapping "Done" calls
/// `sessionNotifier.markAttachmentsDone()` regardless of count —
/// the backend persona handles the zero-attachment case (plan §9).
///
/// **No-removal v1.** Removing a successfully-uploaded image is not
/// supported in v1 — it'd need a server-side delete endpoint. If the
/// user picks the wrong photo they can re-pick (within the count cap)
/// or proceed; the server-side review handles bad evidence.
class AttachmentComposer extends ConsumerStatefulWidget {
  final String personaKey;
  final int bookingId;
  final ChatSession session;
  final AttachmentDirective directive;

  const AttachmentComposer({
    super.key,
    required this.personaKey,
    required this.bookingId,
    required this.session,
    required this.directive,
  });

  @override
  ConsumerState<AttachmentComposer> createState() =>
      _AttachmentComposerState();
}

/// Token-keyed local record of a pick. Two picks of the same image
/// produce distinct tokens so revert (on upload failure) targets the
/// right tile — bytes equality alone is ambiguous and expensive.
///
/// Holds the in-memory bytes (read once via `XFile.readAsBytes()`) +
/// original filename. Bytes drive both the thumbnail (`Image.memory`)
/// and the multipart upload — same path on web and native.
class _PickedItem {
  final int token;
  final String filename;
  final Uint8List bytes;
  const _PickedItem({
    required this.token,
    required this.filename,
    required this.bytes,
  });

  /// Stable string key for the in-flight tracking notifier (which is
  /// keyed by `String`). The token is unique per-pick so this is
  /// injective even if two picks share a filename.
  String get trackingKey => 'pick-$token';
}

class _AttachmentComposerState extends ConsumerState<AttachmentComposer> {
  /// Locally-picked images that have been queued for upload since the
  /// last directive update. Used for the thumbnail grid and the
  /// "X of Y" display. Token-keyed so duplicate paths disambiguate.
  final List<_PickedItem> _uploaded = [];
  int _nextToken = 0;
  bool _finishing = false;

  int get _displayedCount =>
      widget.directive.currentCount + _uploaded.length;

  bool get _atMax => _displayedCount >= widget.directive.maxAllowed;

  Future<void> _pickImage(ImageSource source) async {
    if (_atMax) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    // Read bytes BEFORE the next async hop. On web `picked.path` is a
    // blob: URL with no real File backing — `readAsBytes()` is the
    // only cross-platform way to get the image content.
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    await _upload(filename: picked.name, bytes: bytes);
  }

  Future<void> _upload({
    required String filename,
    required Uint8List bytes,
  }) async {
    final sessionFamily = chatbotSessionProvider(
      personaKey: widget.personaKey,
      bookingId: widget.bookingId,
    );
    final sessionNotifier = ref.read(sessionFamily.notifier);
    // Mint a token before kicking off the round-trip so we can revert
    // *this* specific pick on failure without touching duplicate-name
    // siblings.
    final token = _nextToken++;
    final item = _PickedItem(token: token, filename: filename, bytes: bytes);
    setState(() => _uploaded.add(item));

    final uploadNotifier = ref.read(
      attachmentUploadProvider(widget.session.conversationId).notifier,
    );
    uploadNotifier.markStart(item.trackingKey);

    // Record the session's attachmentsCount before the upload — a
    // successful upload bumps it; a failed upload leaves it unchanged.
    // This is a more reliable signal than comparing error-frame
    // pointers (whose equality contract depends on whether failure
    // subclasses are const).
    final countBefore = ref.read(sessionFamily).hasValue
        ? ref.read(sessionFamily).requireValue.attachmentsCount
        : 0;
    await sessionNotifier.uploadAttachment(filename: filename, bytes: bytes);
    final after = ref.read(sessionFamily);
    final countAfter = after.hasValue
        ? after.requireValue.attachmentsCount
        : countBefore;
    final didUpload = countAfter > countBefore;
    if (!didUpload && mounted) {
      setState(
        () => _uploaded.removeWhere((p) => p.token == token),
      );
    }
    uploadNotifier.markEnd(item.trackingKey);
  }

  Future<void> _showPickerSheet() async {
    if (_atMax) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: ChatbotPalette.brandPrimary,
                ),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: ChatbotPalette.brandPrimary,
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markDone() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref
        .read(
          chatbotSessionProvider(
            personaKey: widget.personaKey,
            bookingId: widget.bookingId,
          ).notifier,
        )
        .markAttachmentsDone();
    if (mounted) setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final inFlight = ref.watch(
      attachmentUploadProvider(widget.session.conversationId),
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ChatbotPalette.composerSurface,
          boxShadow: ChatbotPalette.composerSoftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.directive.hint.isNotEmpty
                        ? widget.directive.hint
                        : 'Add photos as evidence',
                    style: TextStyle(
                      fontSize: 13,
                      color: ChatbotPalette.systemInk,
                    ),
                  ),
                ),
                Text(
                  '$_displayedCount of ${widget.directive.maxAllowed}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ChatbotPalette.brandPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Grid(
              uploaded: _uploaded,
              inFlight: inFlight,
              addEnabled: !_atMax,
              onAddTap: _showPickerSheet,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _finishing ? null : _markDone,
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
              child: _finishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<_PickedItem> uploaded;
  final Set<String> inFlight;
  final bool addEnabled;
  final VoidCallback onAddTap;

  const _Grid({
    required this.uploaded,
    required this.inFlight,
    required this.addEnabled,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final item in uploaded)
        _Thumbnail(
          key: ValueKey(item.token),
          bytes: item.bytes,
          uploading: inFlight.contains(item.trackingKey),
        ),
      _AddTile(enabled: addEnabled, onTap: onAddTap),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Uint8List bytes;
  final bool uploading;

  const _Thumbnail({
    super.key,
    required this.bytes,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image.memory works on every platform; Image.file would fail
          // on web since dart:io's File is unavailable in browsers.
          Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          if (uploading)
            Container(
              color: Colors.black.withValues(alpha: 0.32),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddTile({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? ChatbotPalette.brandPrimary
        : ChatbotPalette.brandPrimary.withValues(alpha: 0.32);
    return Material(
      color: ChatbotPalette.brandPrimaryTint06,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(child: Icon(Icons.add, color: color, size: 28)),
        ),
      ),
    );
  }
}
