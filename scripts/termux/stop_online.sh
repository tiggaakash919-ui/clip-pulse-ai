#!/data/user/0/com.termux/files/usr/bin/bash
# Stop Clip Pulse AI Online Tunnel

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PID_FILE="$REPO_ROOT/data/tunnel.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    kill -9 "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

pkill -9 -f "cloudflared" 2>/dev/null || true
rm -f "$REPO_ROOT/data/public_url.txt"

echo "Clip Pulse AI Online Tunnel stopped. (Local server is still running)."
