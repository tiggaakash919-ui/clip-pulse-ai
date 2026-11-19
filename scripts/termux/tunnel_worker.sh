#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI Cloudflare Tunnel Worker
trap '' HUP
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$REPO_ROOT/data/tunnel.log"

cd "$REPO_ROOT"
exec proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- /root/PeakCut/data/bin/cloudflared tunnel --url http://127.0.0.1:8766 > "$LOG_FILE" 2>&1
