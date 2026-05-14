// State-layer tests for AttachmentUploadNotifier.
//
// This notifier is a pure in-memory `Set<String>` state machine — no
// repository, no async work, no time-based logic. Tests therefore use
// a plain `ProviderContainer` with no overrides; the build() returns
// an empty set synchronously.
//
// Coverage:
//   * markStart adds the path to the in-flight set + isUploading
//     reports true.
//   * markStart then markEnd leaves the set empty.
//   * markEnd on a path that was never markStart-ed is a no-op.
//   * Two markStart calls then one markEnd → the other is still in
//     the set.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/presentation/notifiers/attachment_upload_notifier.dart';

ProviderContainer _build() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initial state is empty', () {
    final c = _build();
    expect(c.read(attachmentUploadProvider(7001)), isEmpty);
  });

  test('markStart adds path; isUploading reports true', () {
    final c = _build();
    final n = c.read(attachmentUploadProvider(7001).notifier);
    n.markStart('/tmp/a.jpg');

    expect(c.read(attachmentUploadProvider(7001)), contains('/tmp/a.jpg'));
    expect(n.isUploading('/tmp/a.jpg'), isTrue);
  });

  test('markStart then markEnd leaves the set empty', () {
    final c = _build();
    final n = c.read(attachmentUploadProvider(7001).notifier);
    n.markStart('/tmp/a.jpg');
    n.markEnd('/tmp/a.jpg');

    expect(c.read(attachmentUploadProvider(7001)), isEmpty);
    expect(n.isUploading('/tmp/a.jpg'), isFalse);
  });

  test('markEnd on a never-started path is a no-op (no exception)', () {
    final c = _build();
    final n = c.read(attachmentUploadProvider(7001).notifier);
    expect(() => n.markEnd('/tmp/ghost.jpg'), returnsNormally);
    expect(c.read(attachmentUploadProvider(7001)), isEmpty);
  });

  test(
    'two markStart calls then one markEnd → the other remains in the set',
    () {
      final c = _build();
      final n = c.read(attachmentUploadProvider(7001).notifier);
      n.markStart('/tmp/a.jpg');
      n.markStart('/tmp/b.jpg');
      n.markEnd('/tmp/a.jpg');

      expect(
        c.read(attachmentUploadProvider(7001)),
        equals({'/tmp/b.jpg'}),
      );
    },
  );

  test('family keys are isolated: 7001 and 8002 do not share state', () {
    final c = _build();
    c.read(attachmentUploadProvider(7001).notifier).markStart('/tmp/a.jpg');
    expect(c.read(attachmentUploadProvider(8002)), isEmpty);
    expect(c.read(attachmentUploadProvider(7001)), contains('/tmp/a.jpg'));
  });
}
