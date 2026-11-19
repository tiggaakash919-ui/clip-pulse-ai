#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI Android/Termux Start Script
# Runs the local server with Android background wake-lock for 24/7 capture

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo "=========================================================="
echo "  Starting Clip Pulse AI Mobile Studio (Phone 24/7 Mode)       "
echo "=========================================================="

# Prevent Android CPU sleep when screen is turned off
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[INFO] Acquiring Termux Wake-Lock (prevents Android sleep)..."
    termux-wake-lock
fi

mkdir -p "$REPO_ROOT/data"
PID_FILE="$REPO_ROOT/data/peakcut.pid"

cleanup() {
    echo ""
    echo "[INFO] Releasing Termux Wake-Lock..."
    if command -v termux-wake-unlock >/dev/null 2>&1; then
        termux-wake-unlock
    fi
    rm -f "$PID_FILE"
    echo "[INFO] Clip Pulse AI stopped cleanly."
}

trap cleanup EXIT INT TERM

echo $$ > "$PID_FILE"
echo "[INFO] Server PID: $$ saved to $PID_FILE"
echo "[INFO] Dashboard accessible on your phone browser at: http://127.0.0.1:8766"
echo "[INFO] Press Ctrl+C or run bash scripts/termux/stop.sh to stop."
echo ""

# Start Clip Pulse AI studio server
if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>&1 | grep -q "ubuntu"; then
    echo "[INFO] Running via high-performance Ubuntu container (Python 3.12 + FFmpeg)..."
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- bash -c "cd /root/PeakCut && python3 -m studio.server"
else
    python -m studio.server
fi
