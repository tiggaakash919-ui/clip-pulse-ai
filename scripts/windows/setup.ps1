# PowerShell Setup Script for PeakCut on Windows (Personal-Use MVP)
# Requires: Windows 10/11 x64, Python 3.10-3.12, FFmpeg, Git

$ErrorActionPreference = "Continue"
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

function Test-PythonCandidate($exePath, $argList = "") {
    if (-not $exePath) { return $false }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exePath
        $psi.Arguments = if ($argList) { "$argList -c `"import sys; print(sys.version_info >= (3, 10))`"" } else { "-c `"import sys; print(sys.version_info >= (3, 10))`"" }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $err = $p.StandardError.ReadToEnd()
        $p.WaitForExit(4000)
        return ($p.ExitCode -eq 0 -and $out -match "True")
    } catch {
        return $false
    }
}

# Check py launcher first
$pyLauncher = Get-Command py -ErrorAction SilentlyContinue
if ($pyLauncher) {
    foreach ($v in @("-3.11", "-3.12", "-3.10")) {
        if (Test-PythonCandidate $pyLauncher.Source $v) {
            $PythonCmd = "py $v"
            break
        }
    }
}

# Check real python.exe (filter out dummy WindowsApps store redirector)
if (-not $PythonCmd) {
    $pyCmds = Get-Command python -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
    foreach ($cmd in $pyCmds) {
        if (Test-PythonCandidate $cmd.Source) {
            $PythonCmd = "`"$($cmd.Source)`""
            break
        }
    }
}

# Also check common default Python install directories
if (-not $PythonCmd) {
    $commonPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:ProgramFiles\Python311\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python312\python.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            if (Test-PythonCandidate $p) {
                $PythonCmd = "`"$p`""
                break
            }
        }
    }
}

if (-not $PythonCmd) {
    Write-Host "`n[WARNING] Real Python 3.10+ was not found on this computer." -ForegroundColor Yellow
    Write-Host "(The WindowsApps shortcut is a dummy Microsoft Store alias, not real Python)." -ForegroundColor Gray
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "`n[INFO] Attempting automated installation via winget..." -ForegroundColor Cyan
        Write-Host "Installing Python 3.11 (official 64-bit)... Please wait." -ForegroundColor Yellow
        winget install Python.Python.3.11 --accept-package-agreements --accept-source-agreements
        Write-Host "`n==========================================================" -ForegroundColor Green
        Write-Host "  Python 3.11 Installation Triggered!                     " -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host "Agar install ho gaya hai, to is window ko CLOSE karein aur" -ForegroundColor White
        Write-Host "setup.bat ko DUBAARA chalaayein taaki Windows naya PATH pehchaan sake." -ForegroundColor White
        exit 0
    } else {
        Write-Host "`n[ACTION REQUIRED] Kripya Python 3.11 manually install karein:" -ForegroundColor Red
        Write-Host "1. Direct download link: https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" -ForegroundColor White
        Write-Host "2. Installer open karein aur pehli screen par neeche tick karein:" -ForegroundColor White
        Write-Host "   >>> [X] Add python.exe to PATH <<< (Ye zaroor check karein!)" -ForegroundColor Yellow
        Write-Host "3. 'Install Now' par click karein." -ForegroundColor White
        Write-Host "4. Installation complete hone ke baad setup.bat dobara chalaayein." -ForegroundColor White
        exit 1
    }
}

try {
    $pyVer = Invoke-Expression "$PythonCmd --version 2>&1"
} catch {
    $pyVer = $PythonCmd
}
Write-Host "Found Python: $pyVer" -ForegroundColor Green

# 2. Check FFmpeg & FFprobe
Write-Host "`n[2/6] Checking FFmpeg and FFprobe..." -ForegroundColor Yellow
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue

if (-not $ffmpeg -or -not $ffprobe) {
    # Check if local bin has it
    $localFfmpeg = Join-Path $RepoRoot "data\bin\ffmpeg.exe"
    $localFfprobe = Join-Path $RepoRoot "data\bin\ffprobe.exe"
    if ((Test-Path $localFfmpeg) -and (Test-Path $localFfprobe)) {
        $env:PATH = "$(Join-Path $RepoRoot "data\bin");" + $env:PATH
        $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
        $ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
    }
}

if (-not $ffmpeg -or -not $ffprobe) {
    Write-Host "`n[WARNING] FFmpeg / FFprobe not found in system PATH." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Attempting to install FFmpeg via winget..." -ForegroundColor Cyan
        winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
        Write-Host "`nFFmpeg install triggered. Kripya is window ko band karke setup.bat dobara chalaayein." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[ACTION REQUIRED] FFmpeg install karein:" -ForegroundColor Red
        Write-Host "1. Download: https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -ForegroundColor White
        Write-Host "2. Extract karke bin folder ko system PATH me add karein ya PeakCut ke data\bin folder me daalein." -ForegroundColor White
        exit 1
    }
}
Write-Host "Found FFmpeg: $($ffmpeg.Source)" -ForegroundColor Green
Write-Host "Found FFprobe: $($ffprobe.Source)" -ForegroundColor Green

# 3. Check NVIDIA GPU / CUDA (Optional)
Write-Host "`n[3/6] Checking Hardware Acceleration (NVIDIA GPU / CUDA)..." -ForegroundColor Yellow
$nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidia) {
    try {
        $gpuName = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
        Write-Host "Detected NVIDIA GPU: $gpuName" -ForegroundColor Green
    } catch {
        Write-Host "NVIDIA driver detected." -ForegroundColor Green
    }
} else {
    Write-Host "No dedicated NVIDIA GPU detected. Running on high-performance CPU mode." -ForegroundColor Gray
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

Write-Host "`nPre-fetching default speech model (Multilingual Whisper)..." -ForegroundColor Yellow
& $VenvPython -m studio.fetch_model

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  PeakCut Setup Complete! Everything is ready!           " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "To start the application, run: .\scripts\windows\start.bat" -ForegroundColor Cyan
Write-Host "Or with Online Link to share with phone: .\scripts\windows\start_online.bat" -ForegroundColor Cyan
