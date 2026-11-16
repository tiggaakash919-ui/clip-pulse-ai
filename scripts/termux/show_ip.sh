#!/data/user/0/com.termux/files/usr/bin/bash
# PeakCut Network IP & Dusra Phone Connection Guide

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PORT=8766
if [ -f "$REPO_ROOT/.env" ]; then
    ENV_PORT=$(grep -E "^PEAKCUT_PORT=" "$REPO_ROOT/.env" | cut -d= -f2 | tr -d ' "')
    if [ -n "$ENV_PORT" ]; then
        PORT="$ENV_PORT"
    fi
fi

# Detect active IP addresses
WIFI_IP=$(python3 -c "
import socket, subprocess, re
ips = []
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(('8.8.8.8', 80))
    ip = s.getsockname()[0]
    if not ip.startswith('127.'):
        ips.append(ip)
    s.close()
except Exception:
    pass

try:
    out = subprocess.check_output(['ifconfig'], stderr=subprocess.DEVNULL, text=True)
    for line in out.splitlines():
        m = re.search(r'inet (?:addr:)?(\d+\.\d+\.\d+\.\d+)', line)
        if m:
            val = m.group(1)
            if not val.startswith('127.') and val not in ips:
                ips.append(val)
except Exception:
    pass

for ip in ips:
    if ip.startswith(('192.168.', '10.', '172.')):
        print(ip)
        break
" 2>/dev/null)

HOTSPOT_IP="192.168.43.1"

echo "=========================================================="
echo "      PEAKCUT - DUSRE PHONE SE CONNECT KARNE KA GUIDE     "
echo "=========================================================="
echo ""
echo "  [METHOD 1] MOBILE HOTSPOT (SABSE SARAL & FASTEST):"
echo "  1. Is phone (Phone 1) ka Mobile Hotspot ON karein."
echo "  2. Dusre phone me Wi-Fi kholkar is Hotspot se connect karein."
echo "  3. Dusre phone ke PeakCut App me tap karein:"
echo "     👉 'Connect via Hotspot (192.168.43.1)'"
echo "     (Ya kisi bhi browser me kholein: http://$HOTSPOT_IP:$PORT/app)"
echo ""
echo "  [METHOD 2] SAME WI-FI ROUTER (Home / Office Wi-Fi):"
echo "  1. Dono phones ko ek hi Wi-Fi se connect karein."
if [ -n "$WIFI_IP" ]; then
    echo "  2. Dusre phone me ye link kholein ya app me enter karein:"
    echo "     👉 http://$WIFI_IP:$PORT/app"
else
    echo "  2. Phone 1 ka Wi-Fi IP check karein (Phone Settings -> Wi-Fi)."
    echo "     👉 http://<PHONE_1_WIFI_IP>:$PORT/app"
fi
echo ""
echo "  [METHOD 3] AUTO-SCAN (NO CONFIG):"
echo "  Dusre phone me PeakCut app kholkar simply tap karein:"
echo "     👉 'Auto-Scan Wi-Fi Network'"
echo "  App khud Phone 1 ko dhundh kar connect kar legi!"
echo "=========================================================="
