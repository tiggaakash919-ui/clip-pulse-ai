# 03. Windows Local-First Setup & Script Guide

This guide provides step-by-step instructions for running PeakCut locally on Windows 10/11 (x64) as a personal-use 24/7 continuous livestream clipping MVP.

---

## 1. System Prerequisites

1. **Operating System**: Windows 10 (Build 19041+) or Windows 11 (64-bit).
2. **Python**: Python 3.10, 3.11, or 3.12. (Python 3.11 x64 recommended).
   - Ensure **"Add Python to PATH"** was checked during installation.
   - Install via winget:
     ```powershell
     winget install Python.Python.3.11
     ```
3. **FFmpeg & FFprobe**:
   - Required for video stream segmentation, audio extraction, and caption burning.
   - Install via winget:
     ```powershell
     winget install Gyan.FFmpeg
     ```
   - Verify in PowerShell:
     ```powershell
     ffmpeg -version
     ffprobe -version
     ```
4. **Git for Windows**:
   - Install via winget:
     ```powershell
     winget install Git.Git
     ```
5. **NVIDIA GPU (Optional but Recommended)**:
   - For fast transcription and video rendering. Tested with CUDA 11.8 / 12.x drivers.

---

## 2. Fast Setup (Using Automated Scripts)

From PowerShell or Command Prompt inside the `PeakCut` repository folder:

### Step 1: Run Setup
```powershell
.\scripts\windows\setup.ps1
```
*Or double-click `scripts\windows\setup.bat` in File Explorer.*

**What this does:**
1. Validates Python, FFmpeg, and FFprobe availability.
2. Checks for NVIDIA GPU acceleration via `nvidia-smi`.
3. Creates an isolated virtual environment at `.venv\`.
4. Installs all required packages from `requirements.txt`.
5. Prepares configuration file `.env` and `data\exported_clips\` folder.
6. Downloads the local multilingual speech recognition model (~140 MB).

---

## 3. Starting the Application (With 24/7 Sleep Prevention)

To start the server:
```powershell
.\scripts\windows\start.ps1
```
*Or double-click `scripts\windows\start.bat`.*

### How Sleep Prevention Works
Windows by default puts idle systems to sleep after 15–30 minutes, which would terminate live video stream ingestion.

`start.ps1` calls the native Windows Win32 API function:
```csharp
[DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint esFlags);
```
With the flags:
- `ES_CONTINUOUS` (`0x80000000`)
- `ES_SYSTEM_REQUIRED` (`0x00000001` - prevents system sleep)
- `ES_AWAYMODE_REQUIRED` (`0x00000040` - allows background recording even if user locks screen)

When you press `Ctrl+C` or run `stop.ps1`, `ES_CONTINUOUS` is restored, returning Windows to your standard power settings.

---

## 4. Stopping the Application Cleanly

To stop the server and any background FFmpeg capture jobs:
```powershell
.\scripts\windows\stop.ps1
```
*Or double-click `scripts\windows\stop.bat`.*

This script:
1. Reads `data\peakcut.pid` and terminates the main server process.
2. Ensures all orphaned FFmpeg child processes are cleanly closed.
3. Restores standard Windows power execution state.
4. Cleans up temporary lock files.

---

## 5. Troubleshooting Common Windows Issues

### Issue 1: PowerShell Execution Policy Error
**Symptom**: `File ... cannot be loaded because running scripts is disabled on this system.`
**Fix**: Run PowerShell with bypass:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\start.ps1
```

### Issue 2: FFmpeg Not Found
**Symptom**: `[ERROR] FFmpeg / FFprobe not found in system PATH.`
**Fix**: Add the folder containing `ffmpeg.exe` (e.g., `C:\ffmpeg\bin`) to your User or System `PATH` environment variable, then restart PowerShell.

### Issue 3: YouTube Rate Limit / Bot Block ("Sign in to confirm you're not a bot")
**Symptom**: `YouTube isn't letting PeakCut download videos right now.`
**Explanation**: YouTube occasionally blocks IP addresses that send automated extraction requests.
**Fix**:
1. Wait 10 minutes (PeakCut's automated circuit breaker backs off automatically).
2. Or export cookies from your browser via a Netscape cookies format extension to `data/cookies.txt` and set `PEAKCUT_YTDLP_COOKIES=data/cookies.txt` in `.env`.

### Issue 4: Out of Disk Space
**Symptom**: Recording stops with note `low disk space (... GB free, safety minimum is 5.0 GB)`.
**Fix**: PeakCut has a safety circuit breaker that halts capture if free disk space falls below `PEAKCUT_DISK_SAFETY_GB` (default 5.0 GB) to protect your Windows system drive. Free up disk space or change the data folder location in `.env` using `PEAKCUT_DATA=D:\PeakCutData`.
