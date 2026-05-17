#!/usr/bin/env bash
# Terminal 2 — Karigar Flutter app on connected phone.
#
# Pointed at the ngrok tunnel from run_server.sh. Defaults to --release
# so the camera enforcement + S-8 cleartext guard are active. Pass
# --profile (or any other --xxx flag) to override.
#
# Loads frontend/.env.local for secrets (Google Maps API key, etc.).
# The .env.local file is gitignored — keys never enter the repo.
#
# Usage:
#   ./run_app.sh           # release on connected device
#   ./run_app.sh --profile # profile (faster hot reload, gallery picker)

set -euo pipefail

NGROK_DOMAIN="${NGROK_DOMAIN:-tried-activity-nuzzle.ngrok-free.dev}"
FRONTEND_DIR="$(cd "$(dirname "$0")/frontend" && pwd)"

# Load secrets from frontend/.env.local so:
#   1. Android Gradle picks up GOOGLE_MAPS_API_KEY via System.getenv
#      (resolves the AndroidManifest meta-data placeholder).
#   2. We can forward it to Dart via --dart-define below.
ENV_LOCAL="$FRONTEND_DIR/.env.local"
if [[ -f "$ENV_LOCAL" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_LOCAL"
  set +a
fi

# Default the maps provider to google when a key is present; falls back
# to osm otherwise so the build never breaks on a missing key.
MAP_PROVIDER="${MAP_PROVIDER:-${GOOGLE_MAPS_API_KEY:+google}}"
MAP_PROVIDER="${MAP_PROVIDER:-osm}"

MODE="${1:---release}"

cd "$FRONTEND_DIR"
exec flutter run "$MODE" \
  --dart-define=BASE_URL="https://$NGROK_DOMAIN/api" \
  --dart-define=BASE_WS_URL="wss://$NGROK_DOMAIN" \
  --dart-define=MAP_PROVIDER="$MAP_PROVIDER" \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}"
