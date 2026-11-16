# PowerShell Start Script for PeakCut (with Windows 24/7 Sleep Prevention)
# Runs the local server and manages execution state.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $RepoRoot

$VenvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    Write-Host "[ERROR] Virtual environment not found. Please run .\scripts\windows\setup.ps1 first." -ForegroundColor Red
    exit 1
}

# Windows Win32 API for preventing idle sleep during continuous 24/7 capture
$ES_CONTINUOUS = [uint32]0x80000000L
$ES_SYSTEM_REQUIRED = [uint32]0x00000001
$ES_AWAYMODE = [uint32]0x00000040
$PreventSleepFlags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_AWAYMODE

try {
    $Win32Sleep = Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
"@ -Name "Win32SleepState" -Namespace "PeakCut" -PassThru -ErrorAction SilentlyContinue

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  Starting PeakCut Local Studio (24/7 Capture Ready)     " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # Prevent system sleep
    Write-Host "[INFO] Preventing Windows idle sleep while PeakCut is running..." -ForegroundColor Yellow
    $Win32Sleep::SetThreadExecutionState($PreventSleepFlags) | Out-Null
} catch {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  Starting PeakCut Local Studio (24/7 Capture Ready)     " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
}

$DataDir = Join-Path $RepoRoot "data"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}
$PidFile = Join-Path $DataDir "peakcut.pid"

# Cleanup on exit
$cleanupBlock = {
    Write-Host "`n[INFO] Restoring normal Windows power / sleep settings..." -ForegroundColor Yellow
    if ($Win32Sleep) {
        try { $Win32Sleep::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null } catch {}
    }
    if (Test-Path $PidFile) {
        Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
    }
}

try {
    # Open browser in background after 2 seconds
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 2
        Start-Process "http://127.0.0.1:8765"
    } | Out-Null

    $pidVal = $PID
    Set-Content -Path $PidFile -Value $pidVal -Force
    Write-Host "[INFO] Server PID: $pidVal saved to $PidFile" -ForegroundColor Gray
    Write-Host "[INFO] Dashboard accessible at: http://127.0.0.1:8765" -ForegroundColor Green
    Write-Host "[INFO] Press Ctrl+C or run .\scripts\windows\stop.ps1 to stop." -ForegroundColor White

    & $VenvPython -m studio.server
} finally {
    & $cleanupBlock
}
