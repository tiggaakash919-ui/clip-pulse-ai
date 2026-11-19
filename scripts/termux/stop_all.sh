#!/data/user/0/com.termux/files/usr/bin/bash
# Stop Clip Pulse AI 24/7 Supervisor, Server, and Cloudflare Tunnel

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Stopping Clip Pulse AI 24/7 Engine and Online Tunnel..."

PID_FILE="$REPO_ROOT/data/supervisor_all.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    kill -9 "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

pkill -9 -f "supervisor_all.sh" 2>/dev/null || true
pkill -9 -f "supervisor.sh" 2>/dev/null || true
pkill -9 -f "studio.server" 2>/dev/null || true
pkill -9 -f "cloudflared" 2>/dev/null || true

rm -f "$REPO_ROOT/data/server.pid" "$REPO_ROOT/data/tunnel.pid" "$REPO_ROOT/data/public_url.txt"

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock 2>/dev/null || true
    echo "[OK] Released Termux Wake-Lock."
fi

echo "Clip Pulse AI 24/7 engine stopped."
