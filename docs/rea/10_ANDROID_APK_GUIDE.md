# 10. Clip Pulse AI Android App (APK Guide)

This guide documents the native Android App built for Clip Pulse AI.

---

## 1. APK Location & Specifications

- **File Path**: `/sdcard/Download/ClipPulseAI.apk` (Download folder)
- **Local Copy**: `/data/user/0/com.termux/files/home/ClipPulse/data/ClipPulseAI.apk`
- **Package Name**: `com.clippulse.app`
- **Application Label**: `Clip Pulse AI`
- **Minimum Android Version**: Android 7.0 (API Level 24)
- **Target Android Version**: Android 14+ (API Level 34)
- **Signatures**: APK Signature Scheme v2 & v3 (Valid & Self-Signed)

---

## 2. Key App Features

1. **Embedded Live Studio**:
   - High-performance WebView configured with DOM storage, hardware acceleration, and full JavaScript execution.
   - Automatically connects to `http://127.0.0.1:8766` on phone startup.
2. **Instant Clip Downloads**:
   - Integrated Android `DownloadManager` saves any exported clip straight to your phone's main Downloads directory with system notification.
3. **Switch Between Phone and PC**:
   - The top action bar includes a **Server** button.
   - **Current Phone Mode**: Set to `http://127.0.0.1:8766`.
   - **Future PC Mode**: When you run Clip Pulse AI on your PC later, simply tap the **Server** button and enter your PC's local WiFi IP (e.g., `http://192.168.1.50:8766`) to control your PC setup directly from your phone!
4. **Offline Detection & Reconnect**:
   - Color-coded status indicator dot (Green = Connected, Orange = Pending, Red = Offline).
   - If the backend is stopped, a clean error screen with a "Retry" button appears.

---

## 3. How to Rebuild the APK

If you make any changes to the Android app layout or code, rebuild it with a single command:
```bash
bash scripts/build_apk.sh
```
This automatically compiles resources, compiles Java sources, runs D8 bytecode dexing, zipaligns, signs with `apksigner`, and copies the fresh APK to `/sdcard/Download/ClipPulseAI.apk`.
