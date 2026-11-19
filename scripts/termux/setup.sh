#!/data/user/0/com.termux/files/usr/bin/bash
# Clip Pulse AI Android/Termux Setup Script
# Configures Clip Pulse AI to run natively on Android inside Termux

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

echo "=========================================================="
echo "  Clip Pulse AI Phone / Termux Setup (Mobile 24/7 Pipeline)    "
echo "=========================================================="
echo "Working Directory: $REPO_ROOT"
echo "TMPDIR: $TMPDIR"

# Check Python
if ! command -v python >/dev/null 2>&1; then
    echo "[ERROR] Python is not installed. Please install it with: pkg install python"
    exit 1
fi
echo "[OK] Python: $(python --version)"

# Check FFmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "[WARNING] ffmpeg is not installed."
    echo "To install on Termux: pkg install ffmpeg"
fi

# Check termux-wake-lock
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[OK] termux-wake-lock available (24/7 screen-off capture supported)."
else
    echo "[NOTE] termux-wake-lock not found. Install 'termux-tools' if you want screen-off capture."
fi

# Create export folder
mkdir -p "$REPO_ROOT/data/exported_clips"
echo "[OK] Clip export directory ready: $REPO_ROOT/data/exported_clips"

# Create phone-optimized .env if not exists
ENV_FILE="$REPO_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    cat << 'EOF' > "$ENV_FILE"
# Clip Pulse AI Mobile (Phone / Termux) Settings
PEAKCUT_HOST=0.0.0.0
PEAKCUT_PORT=8766
PEAKCUT_DATA=data

# Multilingual Speech Model for Phone (Whisper Tiny or Base)
PEAKCUT_ASR_FAMILY=whisper
PEAKCUT_MODEL=sherpa-onnx-whisper-tiny
PEAKCUT_ASR_LANGUAGE=hi

# Mobile Performance Settings
# 720x1280 vertical is 2.5x faster to render on mobile CPU than 1080x1920
PEAKCUT_OUT_W=720
PEAKCUT_OUT_H=1280

# Safety threshold (GB free space required before halting capture)
PEAKCUT_DISK_SAFETY_GB=3.0
EOF
    echo "[OK] Created mobile-optimized .env configuration file."
else
    echo "[OK] Existing .env file found."
fi

echo ""
echo "=========================================================="
echo "  Clip Pulse AI Phone Setup Complete!                          "
echo "=========================================================="
echo "To start on phone: bash scripts/termux/start.sh"
