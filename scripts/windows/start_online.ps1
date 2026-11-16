# PeakCut Windows Online Tunnel (Share with Phone / Remote Friends)
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $RepoRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting PeakCut Online Access (Public HTTPS Link)      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Check if cloudflared is present or download standalone windows exe
$BinDir = Join-Path $RepoRoot "data\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}
$CloudflaredExe = Join-Path $BinDir "cloudflared.exe"
if (-not (Test-Path $CloudflaredExe)) {
    Write-Host "[INFO] Downloading Cloudflare Tunnel engine for Windows..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $CloudflaredExe
}

Write-Host "[INFO] Starting PeakCut server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\start.ps1`""

Start-Sleep -Seconds 3

Write-Host "[INFO] Creating Public HTTPS Tunnel (Ye link apne dost ko share karein)..." -ForegroundColor Green
& $CloudflaredExe tunnel --url http://127.0.0.1:8765
