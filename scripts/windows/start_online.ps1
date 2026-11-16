# PeakCut Windows Online Tunnel (Share with Phone / Remote Friends)
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $RepoRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting PeakCut Online Access (Public HTTPS Link)      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Verify .venv exists or run setup automatically
$VenvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    Write-Host "`n[INFO] First-time setup detected (Virtual environment not found)." -ForegroundColor Yellow
    Write-Host "[INFO] Automatically running setup to prepare everything... Please wait.`n" -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "setup.ps1")
    if (-not (Test-Path $VenvPython)) {
        Write-Host "`n[ERROR] Setup failed. Please ensure Python 3.10-3.12 is installed with 'Add python.exe to PATH'." -ForegroundColor Red
        pause
        exit 1
    }
}

# 2. Check if cloudflared is present or download standalone windows exe
$BinDir = Join-Path $RepoRoot "data\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}
$CloudflaredExe = Join-Path $BinDir "cloudflared.exe"
if (-not (Test-Path $CloudflaredExe)) {
    Write-Host "[INFO] Downloading Cloudflare Tunnel engine for Windows..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $CloudflaredExe
}

# 3. Start local PeakCut server in a separate window
Write-Host "[INFO] Starting PeakCut server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\start.ps1`""

# 4. Wait for local server to be ready on port 8765 before establishing tunnel
Write-Host "[INFO] Waiting for PeakCut server on http://127.0.0.1:8765..." -ForegroundColor Yellow
$serverReady = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 8765)
        $tcp.Close()
        $serverReady = $true
        break
    } catch {}
}

if ($serverReady) {
    Write-Host "[OK] PeakCut server is responding on http://127.0.0.1:8765!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] PeakCut server is taking longer to start. Launching tunnel now..." -ForegroundColor Yellow
}

Write-Host "[INFO] Creating Public HTTPS Tunnel (Ye link apne dost ko share karein)..." -ForegroundColor Green
& $CloudflaredExe tunnel --url http://127.0.0.1:8765
