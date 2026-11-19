# 10. Clip Pulse AI Android App (APK Guide)

This guide documents the native Android App built for Clip Pulse AI.

---

## 1. APK Location & Specifications

- **File Path**: `/sdcard/Download/ClipPulseAI.apk` (Download folder)
- **Local Copy**: `data/ClipPulseAI.apk` inside the project folder
- **Package Name**: `com.clippulse.app`
- **Application Label**: `Clip Pulse AI`
- **Minimum Android Version**: Android 7.0 (API Level 24)
- **Target Android Version**: Android 14+ (API Level 34)
- **Signatures**: APK Signature Scheme v2 & v3 (Valid & Self-Signed)

---

## 2. Key App Features

1. **Native dashboard**:
   - Java screens show engine status, a link box, and the latest videos without opening a browser.
   - The full editor is still one tap away, so every feature of the web app remains available.
2. **Start engine from the app**:
   - **Start engine** asks Termux to run the local ClipPulse server.
   - If the Termux build does not allow external commands, the app copies the start command and opens Termux: paste it and press Enter once.
3. **Job screen**:
   - Tap a video to see its clips, progress, errors and buttons to play or save each clip.
4. **Switch Between Phone and PC**:
   - The top action bar includes a **Server** button.
   - **Current Phone Mode**: Set to `http://127.0.0.1:8766`.
   - **Future PC Mode**: enter your PC's local WiFi IP (e.g., `http://192.168.1.50:8766`) to control your PC setup from your phone.
5. **Offline Detection & Reconnect**:
   - Colour-coded status dot (Green = Connected, Red = Offline), with automatic retries.

---

## 3. How to Rebuild the APK

If you make any changes to the Android app layout or code, rebuild it with a single command:
```bash
bash scripts/build_apk.sh
```
This automatically compiles resources, compiles Java sources, runs D8 bytecode dexing, zipaligns, signs with `apksigner`, and copies the fresh APK to `/sdcard/Download/ClipPulseAI.apk`.
