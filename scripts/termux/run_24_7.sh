#!/data/user/0/com.termux/files/usr/bin/bash
# PeakCut 24/7 Background Starter
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/data"
PID_FILE="$REPO_ROOT/data/peakcut_24_7.pid"
LOG_FILE="$REPO_ROOT/data/server.log"

# Acquire Termux wakelock so CPU never sleeps
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[OK] Termux Wake-Lock acquired (CPU will stay awake when screen is off)."
fi

# Check if already running and responding
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        if curl -s http://127.0.0.1:8766/api/system/preflight >/dev/null 2>&1; then
            echo "[INFO] PeakCut is already running 24/7 (Supervisor PID: $OLD_PID)."
            echo "Dashboard: http://127.0.0.1:8766"
            exit 0
        fi
    fi
fi

# Stop any stale or orphaned processes
bash "$SCRIPT_DIR/stop_24_7.sh" >/dev/null 2>&1 || true

# Re-acquire wake-lock after stop
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi

# Start supervisor in background detached via setsid
chmod +x "$SCRIPT_DIR/supervisor.sh"
setsid "$SCRIPT_DIR/supervisor.sh" </dev/null >/dev/null 2>&1 &
SUPERVISOR_PID=$!
disown 2>/dev/null || true
echo "$SUPERVISOR_PID" > "$PID_FILE"

# Wait up to 15 seconds for server to be responsive
echo "Starting PeakCut engine..."
TRIES=0
MAX_TRIES=15
READY=0
while [ $TRIES -lt $MAX_TRIES ]; do
    if curl -s http://127.0.0.1:8766/api/system/preflight | grep -q '"speech_model_ready":true'; then
        READY=1
        break
    fi
    sleep 1
    TRIES=$((TRIES + 1))
done

if [ $READY -eq 1 ]; then
    echo "=========================================================="
    echo "  PEAKCUT 24/7 ENGINE IS LIVE!                           "
    echo "=========================================================="
    echo "  Dashboard URL: http://127.0.0.1:8766"
    echo "  App URL:       http://127.0.0.1:8766/app"
    echo "  Supervisor:    PID $SUPERVISOR_PID (auto-restart active)"
    echo "  Logs:          $LOG_FILE"
    echo "  Stop command:  bash scripts/termux/stop_24_7.sh"
    echo "=========================================================="
else
    echo "[WARNING] Server took longer than expected to start. Check logs:"
    echo "  tail -n 20 $LOG_FILE"
fi
