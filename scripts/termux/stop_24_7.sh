#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI 24/7 Background Daemon Stop Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo "Stopping Clip Pulse AI 24/7 Daemon..."

PID_FILE="$REPO_ROOT/data/clippulse_24_7.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if [ -n "$PID" ]; then
        kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

# Kill supervisor processes
pkill -9 -f "supervisor.sh" 2>/dev/null || true

# Kill any python studio.server instances
pkill -9 -f "studio.server" 2>/dev/null || true

# Release wake lock
if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
    echo "[OK] Released Termux Wake-Lock."
fi

echo "Clip Pulse AI 24/7 daemon stopped."
