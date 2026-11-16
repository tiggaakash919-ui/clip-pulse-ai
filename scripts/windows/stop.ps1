# PowerShell Stop Script for PeakCut on Windows
# Cleanly terminates server and child capture processes.

$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $RepoRoot

Write-Host "Stopping PeakCut..." -ForegroundColor Yellow

$PidFile = Join-Path $RepoRoot "data\peakcut.pid"
if (Test-Path $PidFile) {
    $procId = Get-Content $PidFile
    if ($procId) {
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        Write-Host "Terminated process ID: $procId" -ForegroundColor Green
    }
    Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
}

# Also ensure any lingering python processes running studio.server are terminated
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "studio\.server" } | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped PeakCut instance (PID: $($_.ProcessId))" -ForegroundColor Green
}

# Reset Windows sleep state
$Win32Sleep = Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
"@ -Name "Win32SleepReset" -Namespace "PeakCutStop" -PassThru

$ES_CONTINUOUS = [uint32]0x80000000
$Win32Sleep::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null

Write-Host "PeakCut stopped cleanly." -ForegroundColor Green
