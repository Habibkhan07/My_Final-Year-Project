/// Which slice of the technician's jobs the user is currently looking at.
///
/// Mirrors the dumb-UI shortcut the segmented control sends as
/// `?segment=upcoming|past` to the backend list endpoint. Resolution
/// into status sets + time windows happens server-side — this enum
/// stays purely about user intent ("what tab am I on").
///
/// Identical wire shape to the customer side's [BookingSegment]: the
/// backend selector for scheduled-jobs accepts the same two literals.
/// The split exists so each feature owns its own segment vocabulary
/// without cross-feature import for a value-type enum.
enum ScheduledJobSegment {
  upcoming,
  past;

  /// Wire string sent on the `?segment=` query param.
  String get wireValue {
    switch (this) {
      case ScheduledJobSegment.upcoming:
        return 'upcoming';
      case ScheduledJobSegment.past:
        return 'past';
    }
  }
}
