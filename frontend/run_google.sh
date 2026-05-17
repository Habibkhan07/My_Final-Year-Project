#!/usr/bin/env bash
# Run the Flutter app with the Google Maps provider.
#
# Loads GOOGLE_MAPS_API_KEY from .env.local (gitignored), then forwards it to:
#   - Android Gradle build (via env var, consumed by android/app/build.gradle.kts:45-46
#     which injects it into AndroidManifest.xml's com.google.android.geo.API_KEY)
#   - Dart runtime (via --dart-define, consumed by lib/core/constants.dart:47
#     for Geocoding / Directions / Places HTTP calls)
#
# Usage: ./run_google.sh                 # default device
#        ./run_google.sh -d <device-id>  # specific device (e.g. -d chrome)
#
# To go back to the free OSM provider, just run `flutter run` without this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Create it with: GOOGLE_MAPS_API_KEY=<your-key>" >&2
  exit 1
fi

# Load the env file. `set -a` exports every assignment that follows.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${GOOGLE_MAPS_API_KEY:-}" || "$GOOGLE_MAPS_API_KEY" == "PASTE_YOUR_KEY_HERE" ]]; then
  echo "ERROR: GOOGLE_MAPS_API_KEY is not set in $ENV_FILE." >&2
  echo "Open .env.local and replace PASTE_YOUR_KEY_HERE with your real key." >&2
  exit 1
fi

cd "$SCRIPT_DIR"
exec flutter run \
  --dart-define=MAP_PROVIDER=google \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  "$@"
