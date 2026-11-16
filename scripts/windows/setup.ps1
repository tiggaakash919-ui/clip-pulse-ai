# PowerShell Setup Script for PeakCut on Windows (Personal-Use MVP)
# Requires: Windows 10/11 x64, Python 3.10-3.12, FFmpeg, Git

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $RepoRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PeakCut Windows Setup & Preflight Check (REA Pipeline) " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Working Directory: $RepoRoot" -ForegroundColor Gray

# 1. Check Python
Write-Host "`n[1/6] Checking Python installation..." -ForegroundColor Yellow
$PythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    foreach ($v in @("-3.11", "-3.12", "-3.10")) {
        $check = py $v -c "import sys; print(sys.version_info >= (3, 10))" 2>$null
        if ($check -match "True") {
            $PythonCmd = "py $v"
            break
        }
    }
}
if (-not $PythonCmd -and (Get-Command python -ErrorAction SilentlyContinue)) {
    $check = python -c "import sys; print(sys.version_info >= (3, 10))" 2>$null
    if ($check -match "True") {
        $PythonCmd = "python"
    }
}

if (-not $PythonCmd) {
    Write-Host "[ERROR] Python 3.10, 3.11, or 3.12 is required but was not found." -ForegroundColor Red
    Write-Host "Install it via winget: winget install Python.Python.3.11" -ForegroundColor Gray
    exit 1
}
$pyVer = Invoke-Expression "$PythonCmd --version"
Write-Host "Found Python: $pyVer" -ForegroundColor Green

# 2. Check FFmpeg & FFprobe
Write-Host "`n[2/6] Checking FFmpeg and FFprobe..." -ForegroundColor Yellow
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffmpeg -or -not $ffprobe) {
    Write-Host "[ERROR] FFmpeg / FFprobe not found in system PATH." -ForegroundColor Red
    Write-Host "Install via winget: winget install Gyan.FFmpeg" -ForegroundColor Gray
    Write-Host "Or download from https://gyan.dev/ffmpeg/builds/ and add the 'bin' folder to PATH." -ForegroundColor Gray
    exit 1
}
Write-Host "Found FFmpeg: $($ffmpeg.Source)" -ForegroundColor Green
Write-Host "Found FFprobe: $($ffprobe.Source)" -ForegroundColor Green

# 3. Check NVIDIA GPU / CUDA (Optional)
Write-Host "`n[3/6] Checking Hardware Acceleration (NVIDIA GPU / CUDA)..." -ForegroundColor Yellow
$nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidia) {
    $gpuName = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
    Write-Host "Detected NVIDIA GPU: $gpuName" -ForegroundColor Green
    Write-Host "CUDA acceleration will be used where compatible." -ForegroundColor Gray
} else {
    Write-Host "No NVIDIA GPU detected or nvidia-smi not in PATH. Running on CPU mode." -ForegroundColor Gray
}

# 4. Create Virtual Environment
Write-Host "`n[4/6] Creating Python Virtual Environment (.venv)..." -ForegroundColor Yellow
$VenvDir = Join-Path $RepoRoot ".venv"
if (-not (Test-Path $VenvDir)) {
    Invoke-Expression "$PythonCmd -m venv `"$VenvDir`""
    Write-Host "Created virtual environment at: $VenvDir" -ForegroundColor Green
} else {
    Write-Host "Virtual environment already exists at: $VenvDir" -ForegroundColor Green
}

$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvPip = Join-Path $VenvDir "Scripts\pip.exe"

# 5. Install Dependencies
Write-Host "`n[5/6] Installing dependencies into .venv..." -ForegroundColor Yellow
& $VenvPython -m pip install --upgrade pip
& $VenvPip install -r (Join-Path $RepoRoot "requirements.txt")

# 6. Configure Environment & Speech Model
Write-Host "`n[6/6] Checking Model & Environment Configuration..." -ForegroundColor Yellow
$EnvFile = Join-Path $RepoRoot ".env"
$EnvExample = Join-Path $RepoRoot ".env.example"
if (-not (Test-Path $EnvFile) -and (Test-Path $EnvExample)) {
    Copy-Item $EnvExample $EnvFile
    Write-Host "Created default .env from .env.example" -ForegroundColor Green
}

# Ensure export directory exists
$ExportDir = Join-Path $RepoRoot "data\exported_clips"
if (-not (Test-Path $ExportDir)) {
    New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
    Write-Host "Created clip export folder at: $ExportDir" -ForegroundColor Green
}

Write-Host "`nAvailable Local Multilingual Speech Models (sherpa-onnx Whisper):" -ForegroundColor Cyan
Write-Host "  1. sherpa-onnx-whisper-base  (~140 MB) [RECOMMENDED: Fast, good for Hindi/English/Hinglish]" -ForegroundColor White
Write-Host "  2. sherpa-onnx-whisper-tiny  (~75 MB)  [Ultra-lightweight for low-end PCs]" -ForegroundColor White
Write-Host "  3. sherpa-onnx-whisper-small (~460 MB) [Higher transcription accuracy]" -ForegroundColor White
Write-Host "`nPre-fetching default speech model..." -ForegroundColor Yellow
& $VenvPython -m studio.fetch_model

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  PeakCut Setup Complete! " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "To start the application, run: .\scripts\windows\start.ps1" -ForegroundColor Cyan
