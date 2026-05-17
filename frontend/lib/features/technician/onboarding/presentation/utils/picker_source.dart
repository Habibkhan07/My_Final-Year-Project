import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Resolves the image-picker source for onboarding image uploads.
///
/// Production builds enforce camera-only capture (the live frame is the
/// only thing we trust for ID + license verification — a photo from the
/// gallery could be a screenshot of someone else's CNIC). Debug builds
/// fall back to the gallery so Android emulators (which have no camera)
/// remain usable for development.
///
/// Pass the *intended* camera as [preferred] — typically
/// ``ImageSource.camera`` (back camera) or ``CameraDevice.front`` flow
/// for the profile-picture selfie. Callers pair this with
/// ``preferredCameraDevice`` on the `ImagePicker` call so release builds
/// land on the right lens.
ImageSource pickerSource(ImageSource preferred) =>
    kReleaseMode ? preferred : ImageSource.gallery;
