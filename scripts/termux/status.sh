#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI 24/7 Status Monitor
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================================="
echo "               CLIP PULSE AI 24/7 LIVE STATUS                   "
echo "=========================================================="

# Check Server
if curl -s --connect-timeout 2 http://127.0.0.1:8766/api/system/preflight | grep -q '"ffmpeg_available":true'; then
    echo "  [Engine Status]        🟢 ONLINE (FastAPI / Uvicorn Active)"
else
    echo "  [Engine Status]        🔴 OFFLINE"
fi

# Check Tunnel
if pgrep -f "cloudflared tunnel" >/dev/null 2>&1; then
    echo "  [Cloudflare Tunnel]    🟢 CONNECTED (Global HTTPS Active)"
else
    echo "  [Cloudflare Tunnel]    🔴 DISCONNECTED"
fi

# Public URL
if [ -f "$REPO_ROOT/data/public_url.txt" ]; then
    echo "  [Global Online Link]   👉 $(cat "$REPO_ROOT/data/public_url.txt")"
fi

echo "  [Local Link]           👉 http://127.0.0.1:8766/app"
echo "  [Hotspot Link]         👉 http://192.168.43.1:8766/app"
echo "=========================================================="
