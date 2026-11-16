#!/data/user/0/com.termux/files/usr/bin/bash
# PeakCut 24/7 Unified Self-Healing Supervisor Loop
trap '' HUP
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$REPO_ROOT/data"
SERVER_LOG="$LOG_DIR/server.log"
TUNNEL_LOG="$LOG_DIR/tunnel.log"
URL_FILE="$LOG_DIR/public_url.txt"
SDCARD_URL="/sdcard/Download/peakcut_online_url.txt"

mkdir -p "$LOG_DIR" "$LOG_DIR/bin"
cd "$REPO_ROOT"

# Ensure Termux wakelock is held
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock 2>/dev/null || true
fi

start_server() {
    echo "[$(date)] Starting PeakCut backend engine..." >> "$SERVER_LOG"
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- bash -c "cd /root/PeakCut && exec python3 -m studio.server" >> "$SERVER_LOG" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$LOG_DIR/server.pid"
}

start_tunnel() {
    echo "[$(date)] Starting Cloudflare global online tunnel..." >> "$TUNNEL_LOG"
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- /root/PeakCut/data/bin/cloudflared tunnel --url http://127.0.0.1:8766 >> "$TUNNEL_LOG" 2>&1 &
    TUNNEL_PID=$!
    echo $TUNNEL_PID > "$LOG_DIR/tunnel.pid"
}

# Main self-healing supervisor loop
while true; do
    # 1. Check PeakCut Server
    if ! curl -s --connect-timeout 2 http://127.0.0.1:8766/api/system/preflight >/dev/null 2>&1; then
        echo "[$(date)] PeakCut backend is not responding. Starting..." >> "$SERVER_LOG"
        pkill -9 -f "studio.server" 2>/dev/null || true
        start_server
        sleep 4
    fi

    # 2. Check Cloudflare Tunnel
    if ! pgrep -f "cloudflared tunnel" >/dev/null 2>&1; then
        echo "[$(date)] Cloudflare tunnel is not running. Starting..." >> "$TUNNEL_LOG"
        start_tunnel
        sleep 5
    fi

    # 3. Extract and update latest Public URL
    if [ -f "$TUNNEL_LOG" ]; then
        LATEST_URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com" "$TUNNEL_LOG" | tail -n 1)
        if [ -n "$LATEST_URL" ]; then
            CURRENT_APP_URL="$LATEST_URL/app"
            echo "$CURRENT_APP_URL" > "$URL_FILE"
            if [ -d "/sdcard/Download" ]; then
                {
                    echo "=========================================================="
                    echo "PEAKCUT 24/7 LIVE ONLINE LINK (Apne dost ke sath share karein):"
                    echo "$CURRENT_APP_URL"
                    echo ""
                    echo "Local Address (Phone 1):   http://127.0.0.1:8766/app"
                    echo "Hotspot Address (Phone 2): http://192.168.43.1:8766/app"
                    echo "Updated at: $(date)"
                    echo "=========================================================="
                } > "$SDCARD_URL" 2>/dev/null || true
            fi
        fi
    fi

    sleep 5
done
