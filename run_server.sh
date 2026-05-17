#!/usr/bin/env bash
# Terminal 1 — Karigar backend stack.
#
# Foregrounds Django runserver so you see every API request in real time.
# Ngrok runs in the background; its inspection URL prints once at boot
# so you can open http://127.0.0.1:4040 in a browser if you want the
# full HTTP-by-HTTP timeline.
#
# Ctrl+C cleanly kills both Django and ngrok.

set -euo pipefail

NGROK_DOMAIN="${NGROK_DOMAIN:-tried-activity-nuzzle.ngrok-free.dev}"
BACKEND_DIR="$(cd "$(dirname "$0")/backend" && pwd)"

echo "▶ Killing any stray runserver / ngrok ..."
pkill -f "manage.py runserver" 2>/dev/null || true
pkill -f "ngrok http" 2>/dev/null || true
sleep 1

echo "▶ Starting ngrok tunnel: https://$NGROK_DOMAIN → :8000"
ngrok http --domain="$NGROK_DOMAIN" 8000 \
  > /tmp/karigar_ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to be ready
sleep 2

# Print the tunnel URL + inspector
cat <<EOF

╔════════════════════════════════════════════════════════════════╗
║  Public URL:  https://$NGROK_DOMAIN
║  Inspector:   http://127.0.0.1:4040
║  Django log: streaming below ↓
╚════════════════════════════════════════════════════════════════╝

EOF

trap 'echo; echo "▶ Stopping ngrok..."; kill $NGROK_PID 2>/dev/null || true' EXIT

cd "$BACKEND_DIR"
source venv/bin/activate
exec python manage.py runserver 0.0.0.0:8000
