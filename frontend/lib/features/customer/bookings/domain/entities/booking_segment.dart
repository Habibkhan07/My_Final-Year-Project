/// Which slice of bookings the user is currently looking at.
///
/// Mirrors the dumb-UI shortcut the segmented control sends as
/// `?segment=upcoming|past` to the backend list endpoint. Resolution
/// into status sets + time windows happens server-side — this enum
/// stays purely about user intent ("what tab am I on").
enum BookingSegment {
  upcoming,
  past;

  /// Wire string sent on the `?segment=` query param.
  String get wireValue {
    switch (this) {
      case BookingSegment.upcoming:
        return 'upcoming';
      case BookingSegment.past:
        return 'past';
    }
  }
}
