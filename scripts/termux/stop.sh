#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI Android/Termux Stop Script
# Cleanly terminates server and releases Termux wake-lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo "Stopping Clip Pulse AI on Phone..."

PID_FILE="$REPO_ROOT/data/peakcut.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        echo "Stopped server PID: $PID"
    fi
    rm -f "$PID_FILE"
fi

# Ensure any background studio.server processes are killed
pkill -f "studio.server" 2>/dev/null || true

# Release wake lock
if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
    echo "Released Termux Wake-Lock."
fi

echo "Clip Pulse AI stopped."
