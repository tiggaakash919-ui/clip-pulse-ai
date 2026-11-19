#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI 24/7 Supervisor Loop
trap '' HUP
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$REPO_ROOT/data/server.log"

cd "$REPO_ROOT"

while true; do
    echo "[$(date)] Starting Clip Pulse AI server..." >> "$LOG_FILE"
    proot-distro login ubuntu --bind "$REPO_ROOT":/root/PeakCut -- bash -c "cd /root/PeakCut && python3 -m studio.server" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?
    echo "[$(date)] Server exited with code $EXIT_CODE. Restarting in 2 seconds..." >> "$LOG_FILE"
    sleep 2
done
