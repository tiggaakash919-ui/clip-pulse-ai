# 09. Running PeakCut on Android Phone (Termux Mobile Guide)

This guide explains how to run PeakCut directly on your Android phone using Termux for 24/7 continuous YouTube livestream clipping.

---

## 1. Mobile Optimizations & Hardware Strategy

Running a video AI pipeline on a mobile smartphone requires specific optimizations to prevent battery drain, thermal throttling, and system lag:

| Parameter | Standard Desktop Setting | Mobile Phone / Termux Setting | Benefit on Phone |
|---|---|---|---|
| **Speech Model** | `sherpa-onnx-whisper-base` (~140 MB) | **`sherpa-onnx-whisper-tiny`** (~75 MB) | 3x lower RAM usage, instantaneous transcription on mobile CPU |
| **Output Resolution** | 1080x1920 (Full HD) | **720x1280 (HD)** | **2.5x faster FFmpeg rendering**, prevents phone overheating |
| **Disk Safety Minimum** | 5.0 GB | **3.0 GB** | Accommodates smaller internal smartphone storage |
| **Sleep Prevention** | Win32 `SetThreadExecutionState` | **`termux-wake-lock`** | Prevents Android OS from killing background process when screen is locked |

---

## 2. Package Prerequisites on Android

To run natively in Termux:
1. **FFmpeg**: Required to slice livestream video, extract audio, and burn captions.
   - Install command: `pkg install ffmpeg`
2. **Precompiled Python C-Extensions**:
   - `pkg install python-numpy python-pillow libsoundfile`
   - *Note: In Termux, installing numpy via `pip` attempts to compile 20MB of C sources which overheats the phone. Using Termux prebuilt binary packages (`pkg`) installs them in seconds.*
3. **Pip Dependencies**:
   - `pip install sherpa-onnx yt-dlp httpx SQLAlchemy fastapi uvicorn soundfile`

---

## 3. How Android 24/7 Screen-Off Capture Works

When you lock your phone or turn off the screen, Android's battery manager normally suspends app CPU cycles.

PeakCut's mobile runner ([`scripts/termux/start.sh`](file:///data/user/0/com.termux/files/home/PeakCut/scripts/termux/start.sh)) calls:
```bash
termux-wake-lock
```
This tells Android: *"Keep the CPU active in low-power state for background processing."*
When you press `Ctrl+C` or run [`scripts/termux/stop.sh`](file:///data/user/0/com.termux/files/home/PeakCut/scripts/termux/stop.sh), `termux-wake-unlock` is called, restoring normal battery saving.

---

## 4. Step-by-Step Instructions on Phone

### Step 1: Run Setup
```bash
bash scripts/termux/setup.sh
```
This prepares the directories, creates the mobile-tuned `.env` file, and validates your environment.

### Step 2: Start Studio Server
```bash
bash scripts/termux/start.sh
```
- A wakelock is acquired.
- The server starts at `http://127.0.0.1:8765`.

### Step 3: Open Dashboard on Phone
Open your phone's web browser (Chrome, Brave, Firefox, etc.) and go to:
```
http://127.0.0.1:8765
```
Paste your YouTube livestream URL, select genre (Gaming, Podcast, IRL, General), and click **Start**.

### Step 4: Accessing Generated Clips
Final ready clips are saved in:
```
/data/user/0/com.termux/files/home/PeakCut/data/exported_clips/
```
In this chat, clips can be played directly with:
```markdown
![Clip](/data/user/0/com.termux/files/home/PeakCut/data/exported_clips/clip_123.mp4)
```
Or you can view/copy them to your phone's main storage (`/sdcard/Movies/` or `/sdcard/Download/`).
