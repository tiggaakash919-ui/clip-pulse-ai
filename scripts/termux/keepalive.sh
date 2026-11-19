#!/data/user/0/com.termux/files/usr/bin/bash
# Keeps the Clip Pulse AI engine running on the phone.
# - If the engine is already answering, this does nothing.
# - If it stops (a crash, low memory, a reboot), it starts again after a few seconds.
# Start it once from Termux; after that the app finds the engine by itself.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

# Which port the engine uses: CLIPPULSE_PORT, else the one written in .env, else 8766.
PORT="${CLIPPULSE_PORT:-}"
if [ -z "$PORT" ] && [ -f .env ]; then
    PORT="$(sed -n 's/^CLIPPULSE_PORT=//p' .env | head -1 | tr -d '\r "')"
fi
PORT="${PORT:-8766}"

engine_up() {
    (exec 3<>"/dev/tcp/127.0.0.1/${PORT}") >/dev/null 2>&1
}

# A sleep that lets Ctrl+C through straight away, instead of after the wait ends.
pause() {
    sleep "$1" &
    wait $! 2>/dev/null || true
}

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock            # the phone must not sleep while the engine works
fi
trap 'command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock; exit 0' INT TERM

echo "=========================================================="
echo "  Clip Pulse AI engine (kept running)                     "
echo "=========================================================="
echo "[INFO] Dashboard: http://127.0.0.1:${PORT}   (Ctrl+C to stop)"

fails=0
while true; do
    if engine_up; then
        fails=0
        pause 30               # already running (started by the app, or an older window): leave it alone
        continue
    fi

    bash "$SCRIPT_DIR/start.sh"
    code=$?

    case "$code" in
        0|130|143) break ;;     # Ctrl+C was pressed: stop for good
    esac

    fails=$((fails + 1))
    if [ "$fails" -ge 5 ]; then
        echo "[INFO] The engine keeps stopping (code $code). Waiting a minute before trying again."
        pause 60
        fails=0
    else
        echo "[INFO] The engine stopped (code $code). Starting it again in 5 seconds..."
        pause 5
    fi
done
