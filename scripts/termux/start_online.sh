#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI Global Online Public Access (Cloudflare Tunnel)
# Allows anyone, anywhere in the world to open Clip Pulse AI via a secure HTTPS link.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/data/bin"
CLOUDFLARED="$REPO_ROOT/data/bin/cloudflared"
TUNNEL_LOG="$REPO_ROOT/data/tunnel.log"
URL_FILE="$REPO_ROOT/data/public_url.txt"
PID_FILE="$REPO_ROOT/data/tunnel.pid"

# Ensure Clip Pulse AI server is running
if ! curl -s http://127.0.0.1:8766/api/system/preflight >/dev/null 2>&1; then
    echo "[INFO] Starting Clip Pulse AI backend first..."
    bash "$SCRIPT_DIR/run_24_7.sh"
    sleep 3
fi

# Ensure cloudflared binary is available
if [ ! -f "$CLOUDFLARED" ]; then
    echo "[INFO] Downloading Cloudflare Tunnel engine (aarch64)..."
    proot-distro login ubuntu -- bash -c "curl -L -s https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /tmp/cloudflared && chmod +x /tmp/cloudflared"
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- bash -c "cp /tmp/cloudflared /root/PeakCut/data/bin/cloudflared && chmod +x /root/PeakCut/data/bin/cloudflared"
fi

# Stop any previous tunnel
bash "$SCRIPT_DIR/stop_online.sh" >/dev/null 2>&1 || true

rm -f "$TUNNEL_LOG" "$URL_FILE"

echo "[1/2] Connecting to global Cloudflare network..."

# Launch tunnel worker detached via setsid
chmod +x "$SCRIPT_DIR/tunnel_worker.sh"
setsid "$SCRIPT_DIR/tunnel_worker.sh" </dev/null >/dev/null 2>&1 &
TUNNEL_PID=$!
disown 2>/dev/null || true
echo "$TUNNEL_PID" > "$PID_FILE"

# Wait for public URL to appear in log
TRIES=0
PUBLIC_URL=""
while [ $TRIES -lt 25 ]; do
    if [ -f "$TUNNEL_LOG" ]; then
        PUBLIC_URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com" "$TUNNEL_LOG" | head -n 1)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
    sleep 1
    TRIES=$((TRIES + 1))
done

if [ -n "$PUBLIC_URL" ]; then
    echo "$PUBLIC_URL/app" > "$URL_FILE"
    echo ""
    echo "=========================================================="
    echo "       CLIP PULSE AI IS NOW LIVE ON THE INTERNET!         "
    echo "=========================================================="
    echo ""
    echo "  Apne dost ko ye link WhatsApp / Telegram par bhej dein:"
    echo ""
    echo "  👉  $PUBLIC_URL/app"
    echo ""
    echo "  Khas Baatein:"
    echo "  - Aapka dost 1 km dur ho ya 1000 km dur, wo apne mobile"
    echo "    ya computer ke kisi bhi browser (Chrome/Safari) me"
    echo "    ye link khol kar stream paste karke clips bana sakta hai!"
    echo "  - Phone 2 ke Clip Pulse AI App me 'Enter Host IP / URL' me"
    echo "    bhi ye link daal sakte hain."
    echo "  - Free, fast aur automatic HTTPS SSL secure connection."
    echo ""
    echo "  Online link band karne ke liye:"
    echo "  bash scripts/termux/stop_online.sh"
    echo "=========================================================="
else
    echo "[ERROR] Tunnel connection timed out. Check logs:"
    cat "$TUNNEL_LOG" 2>/dev/null | tail -n 15
fi
