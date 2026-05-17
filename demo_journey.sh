#!/usr/bin/env bash
# Single-command setup for the customer ↔ tech booking-journey demo.
#
# Sequence:
#   1. wipe_all_except_catalog    — full reset (users, addresses, bookings,
#                                    wallet, profiles); preserves only the
#                                    `hamayon` admin and the catalog app
#   2. adb shell pm clear         — clear stale active_job_id on the phone
#   3. seed_online_toggle unlocked — tech wallet = +Rs. 500, unlocked
#   4. seed_test_fixtures         — fresh AWAITING booking + prints tokens
#   5. dev_panel                  — interactive driver (drives every state)
#
# Usage:
#   ./demo_journey.sh              # full reset + dev_panel
#   ./demo_journey.sh --no-clear   # skip adb (no device connected / web build)
#   ./demo_journey.sh --no-panel   # do steps 1-4, skip the interactive panel
#
# After the script lands you in dev_panel:
#   - On the phone: log in as customer  +923002222222 / OTP 123456
#   - On the laptop: press 2 (Confirm), 3 (Depart), 4 (GPS sim), then
#     6, 7, 9 in order. Watch the customer's live tracking map update.

set -euo pipefail

# -------- args --------
CLEAR_APP=true
RUN_PANEL=true
for arg in "$@"; do
  case "$arg" in
    --no-clear) CLEAR_APP=false ;;
    --no-panel) RUN_PANEL=false ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# -------- paths --------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
ANDROID_PKG="com.example.frontend"

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "ERROR: $BACKEND_DIR not found." >&2
  exit 1
fi
cd "$BACKEND_DIR"

# Activate venv if present (matches the rest of the repo's convention).
if [[ -f "$BACKEND_DIR/venv/bin/activate" ]]; then
  # shellcheck disable=SC1091
  source "$BACKEND_DIR/venv/bin/activate"
fi

# -------- helpers --------
hr() { printf '\n\033[1;36m── %s ──\033[0m\n' "$1"; }
ok() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$1"; }

# -------- 1. full reset (users + addresses + bookings + wallet + profiles) --------
hr "1/4  Full reset (preserving catalog + 'hamayon' admin)"
python manage.py wipe_all_except_catalog --keep-username hamayon
ok "non-catalog data cleared; 'hamayon' admin preserved"

# -------- 2. clear app data on phone --------
if $CLEAR_APP; then
  hr "2/4  Clearing app cache on device"
  if command -v adb >/dev/null 2>&1; then
    if adb devices | grep -qE 'device$|emulator'; then
      adb shell pm clear "$ANDROID_PKG" \
        && ok "app data cleared for $ANDROID_PKG" \
        || warn "adb pm clear failed (app not installed?); continuing"
    else
      warn "no adb device connected; skipping app-data clear"
      warn "if the customer/tech app is open, expect 404 polling on stale active_job_id"
    fi
  else
    warn "adb not on PATH; skipping app-data clear"
  fi
else
  warn "skipping app-data clear (--no-clear)"
fi

# -------- 3. unlock tech wallet --------
hr "3/4  Seeding tech wallet to +Rs. 500 (unlocked)"
python manage.py seed_online_toggle --scenario unlocked
ok "tech is APPROVED, is_active=True, balance=+500"

# -------- 4. fresh fixture + AWAITING booking --------
hr "4/4  Seeding fresh AWAITING booking"
python manage.py seed_test_fixtures
ok "fixture ready — copy the booking_id + tech_token printed above"

# -------- 5. dev_panel (interactive) --------
if $RUN_PANEL; then
  hr "Launching dev_panel (Ctrl+C or 'q' to exit)"
  echo
  echo "  Customer  : +923002222222 / OTP 123456"
  echo "  Tech      : +923001111111 / OTP 123456"
  echo
  echo "  Suggested press order:  2  3  4  (wait for ARRIVED)  6  7  9"
  echo
  exec python manage.py dev_panel
else
  hr "All set — dev_panel skipped (--no-panel)"
  echo "  Run manually:  cd backend && python manage.py dev_panel"
fi
