#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI 24/7 Unified Background Starter (Server + Global Online Tunnel)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

LOG_DIR="$REPO_ROOT/data"
PID_FILE="$LOG_DIR/supervisor_all.pid"
URL_FILE="$LOG_DIR/public_url.txt"
SDCARD_URL="/sdcard/Download/clippulse_online_url.txt"

mkdir -p "$LOG_DIR" "$LOG_DIR/bin"

# Acquire Termux wakelock so CPU never sleeps
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[OK] Termux Wake-Lock acquired (CPU screen off hone par bhi sleep nahi hoga)."
fi

# Ensure cloudflared binary is available
CLOUDFLARED="$LOG_DIR/bin/cloudflared"
if [ ! -f "$CLOUDFLARED" ]; then
    echo "[INFO] Downloading Cloudflare Tunnel engine..."
    proot-distro login ubuntu -- bash -c "curl -L -s https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /tmp/cloudflared && chmod +x /tmp/cloudflared"
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/ClipPulse -- bash -c "cp /tmp/cloudflared /root/ClipPulse/data/bin/cloudflared && chmod +x /root/ClipPulse/data/bin/cloudflared"
fi

# Check if supervisor is already running and healthy
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        if curl -s --connect-timeout 2 http://127.0.0.1:8766/api/system/preflight >/dev/null 2>&1; then
            echo "[INFO] Clip Pulse AI 24/7 is ALREADY RUNNING (Supervisor PID: $OLD_PID)."
            if [ -f "$URL_FILE" ]; then
                echo "Global Online Link: $(cat "$URL_FILE")"
            fi
            echo "Local Link:         http://127.0.0.1:8766/app"
            echo "Hotspot Link:       http://192.168.43.1:8766/app"
            exit 0
        fi
    fi
fi

# Stop any stale instances
bash "$SCRIPT_DIR/stop_all.sh" >/dev/null 2>&1 || true

# Re-acquire wake lock after stop
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock 2>/dev/null || true
fi

# Start the unified supervisor in the background detached via setsid
chmod +x "$SCRIPT_DIR/supervisor_all.sh"
setsid "$SCRIPT_DIR/supervisor_all.sh" </dev/null >/dev/null 2>&1 &
SUPERVISOR_PID=$!
disown 2>/dev/null || true
echo "$SUPERVISOR_PID" > "$PID_FILE"

echo "[1/2] Starting Clip Pulse AI 24/7 Engine & Cloudflare Tunnel..."

# Wait for server to become responsive
TRIES=0
while [ $TRIES -lt 15 ]; do
    if curl -s --connect-timeout 1 http://127.0.0.1:8766/api/system/preflight >/dev/null 2>&1; then
        break
    fi
    sleep 1
    TRIES=$((TRIES + 1))
done

# Wait for public URL to be generated
TRIES=0
PUBLIC_URL=""
while [ $TRIES -lt 20 ]; do
    if [ -f "$URL_FILE" ]; then
        PUBLIC_URL=$(cat "$URL_FILE")
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
    sleep 1
    TRIES=$((TRIES + 1))
done

echo ""
echo "=========================================================="
echo "    CLIP PULSE AI 24/7 UNATTENDED AUTOMATION IS ACTIVE!         "
echo "=========================================================="
echo ""
echo "  [1] GLOBAL ONLINE LINK (Dost ke sath share karein):"
if [ -n "$PUBLIC_URL" ]; then
    echo "      👉 $PUBLIC_URL"
else
    echo "      Generating tunnel link... check: cat data/public_url.txt"
fi
echo ""
echo "  [2] LOCAL DASHBOARD (Is phone par):"
echo "      👉 http://127.0.0.1:8766/app"
echo ""
echo "  [3] HOTSPOT (Dusre phone ke liye direct):"
echo "      👉 http://192.168.43.1:8766/app"
echo ""
echo "  [4] ONLINE LINK SAVED AT:"
echo "      👉 /sdcard/Download/clippulse_online_url.txt"
echo ""
echo "  To stop everything:"
echo "      bash scripts/termux/stop_all.sh"
echo "=========================================================="
