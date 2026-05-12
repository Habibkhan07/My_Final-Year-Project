#!/usr/bin/env bash
# auto_demo.sh — one-terminal end-to-end customer-side demo.
#
# Runs the backend, seeds fixtures, then auto-progresses one booking
# through every customer-visible orchestrator state with delays in
# between so you can watch the Chrome client react to each event.
#
#   AWAITING → CONFIRMED → EN_ROUTE → ARRIVED → INSPECTING
#            → QUOTED → IN_PROGRESS → COMPLETED
#
# During EN_ROUTE/ARRIVED, fake_tech_gps.py streams GPS frames so the
# LiveTrackingMap shows a moving tech marker.
#
# Usage:
#   ./auto_demo.sh                     # default 12s between transitions
#   DELAY=20 ./auto_demo.sh            # slower walk for screenshots
#   DELAY=5  ./auto_demo.sh            # speed-run
#
# Companion command (separate terminal — Flutter only):
#   cd frontend && flutter run -d chrome --dart-define=MAP_PROVIDER=osm
#   then log in: phone +923002222222, OTP 123456

set -euo pipefail

# ---------------------------------------------------------------------------
# locate repo + venv
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
PY="$BACKEND_DIR/venv/bin/python"

if [[ ! -x "$PY" ]]; then
  echo "✗ venv python not found at $PY"
  echo "  Create it with: cd backend && python3 -m venv venv && ./venv/bin/pip install -r requirements.txt"
  exit 1
fi

cd "$BACKEND_DIR"

# Tunables
DELAY="${DELAY:-12}"          # seconds between state transitions
LOG_DIR="${LOG_DIR:-/tmp/fyp_demo}"
mkdir -p "$LOG_DIR"

# ---------------------------------------------------------------------------
# cleanup on exit — kill background server + GPS broadcaster
# ---------------------------------------------------------------------------
SERVER_PID=""
GPS_PID=""

cleanup() {
  echo ""
  echo "── shutting down ──────────────────────────────────────────"
  [[ -n "$GPS_PID" ]]    && kill "$GPS_PID"    2>/dev/null && echo "  ✓ stopped fake GPS"
  [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null && echo "  ✓ stopped backend (logs: $LOG_DIR/backend.log)"
  echo "  ✓ done"
}
trap cleanup EXIT INT TERM

step_msg() {
  echo ""
  echo "── $1 ─────────────────────────────────────────────"
}

wait_with_countdown() {
  local seconds=$1
  local msg="${2:-watching Chrome update}"
  for ((i=seconds; i>0; i--)); do
    printf "\r  ⏳ %s — %2ds " "$msg" "$i"
    sleep 1
  done
  printf "\r%-70s\n" ""  # clear line
}

# ---------------------------------------------------------------------------
# 1. migrate (idempotent — no-op if up to date)
# ---------------------------------------------------------------------------
step_msg "1/4 applying migrations"
"$PY" manage.py migrate --no-input 2>&1 | tail -5

# ---------------------------------------------------------------------------
# 2. start backend in background
# ---------------------------------------------------------------------------
step_msg "2/4 starting Django runserver"
"$PY" manage.py runserver 0.0.0.0:8000 > "$LOG_DIR/backend.log" 2>&1 &
SERVER_PID=$!
echo "  PID=$SERVER_PID  logs=$LOG_DIR/backend.log"

# Wait for it to come up (max 30s)
echo "  waiting for backend to be reachable..."
for i in {1..60}; do
  if curl -sf -o /dev/null http://localhost:8000/admin/login/; then
    echo "  ✓ backend up"
    break
  fi
  sleep 0.5
  if [[ $i -eq 60 ]]; then
    echo "  ✗ backend didn't come up in 30s; check $LOG_DIR/backend.log"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# 3. seed fixtures
# ---------------------------------------------------------------------------
step_msg "3/4 seeding fixtures + 1 fresh booking"
SEED_OUT=$("$PY" manage.py seed_test_fixtures --count 1)
echo "$SEED_OUT"

BOOKING_ID=$(echo "$SEED_OUT" | awk '/booking_id =/ {print $NF; exit}')
TECH_TOKEN=$(echo "$SEED_OUT"  | awk '/Tech token/    {print $NF; exit}')

if [[ -z "$BOOKING_ID" || -z "$TECH_TOKEN" ]]; then
  echo "✗ failed to parse booking_id / tech_token from seeder output"
  exit 1
fi

# ---------------------------------------------------------------------------
# 4. log in and open the booking
# ---------------------------------------------------------------------------
cat <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  OPEN CHROME NOW                                                 ║
║                                                                  ║
║  1. In the terminal where Flutter is running:                    ║
║       cd frontend && flutter run -d chrome --dart-define=MAP_PROVIDER=osm
║                                                                  ║
║  2. Log in:                                                      ║
║       Phone : +923002222222                                      ║
║       OTP   : 123456                                             ║
║                                                                  ║
║  3. Open booking #${BOOKING_ID}                                                ║
║                                                                  ║
║  Demo auto-starts in 30s. State changes every ${DELAY}s.                  ║
╚══════════════════════════════════════════════════════════════════╝

EOF

wait_with_countdown 30 "log in and open booking #$BOOKING_ID"

# ---------------------------------------------------------------------------
# 5. state walk
# ---------------------------------------------------------------------------
drive() {
  local label="$1"; shift
  step_msg "$label"
  "$PY" manage.py drive_booking "$BOOKING_ID" "$@"
}

drive "AWAITING → CONFIRMED" confirm
wait_with_countdown "$DELAY"

drive "CONFIRMED → EN_ROUTE" depart
wait_with_countdown 3 "starting GPS broadcaster"

step_msg "starting fake_tech_gps for booking #$BOOKING_ID"
"$PY" scripts/fake_tech_gps.py \
    --booking-id "$BOOKING_ID" \
    --token "$TECH_TOKEN" \
    --mode steady > "$LOG_DIR/gps.log" 2>&1 &
GPS_PID=$!
echo "  PID=$GPS_PID  logs=$LOG_DIR/gps.log"
wait_with_countdown "$DELAY" "tech driving — map should be moving"

drive "EN_ROUTE → ARRIVED" arrive
wait_with_countdown "$DELAY" "tech at the door — map should shrink"

step_msg "stopping fake_tech_gps"
kill "$GPS_PID" 2>/dev/null && echo "  ✓ stopped"
GPS_PID=""

drive "ARRIVED → INSPECTING" start_inspection
wait_with_countdown "$DELAY"

drive "INSPECTING → QUOTED" quote
wait_with_countdown "$DELAY" "review the quote card on Chrome"

drive "QUOTED → IN_PROGRESS" approve_quote
wait_with_countdown "$DELAY"

drive "IN_PROGRESS → COMPLETED" complete_cash

# ---------------------------------------------------------------------------
# 6. done — keep backend running so the user can keep exploring
# ---------------------------------------------------------------------------
cat <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  ✓ DEMO COMPLETE                                                 ║
║                                                                  ║
║  Booking #${BOOKING_ID} is now COMPLETED.                                    ║
║  Backend is still running — press Ctrl+C to stop everything.     ║
║                                                                  ║
║  To replay: re-run this script (it'll mint a fresh booking).     ║
╚══════════════════════════════════════════════════════════════════╝

EOF

# Block on the server so Ctrl+C cleanly tears down via the trap
wait "$SERVER_PID"
