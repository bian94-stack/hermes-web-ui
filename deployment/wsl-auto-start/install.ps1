# Hermes Web UI - Windows Auto-Start Installer
# Run this script in Windows PowerShell (Administrator)

param(
    [string]$WSLUser = "z",
    [string]$WSLDistro = "Ubuntu"
)

Write-Host "=== Hermes Web UI - Windows Auto-Start Installer ===" -ForegroundColor Cyan
Write-Host "WSL User: $WSLUser"
Write-Host "WSL Distro: $WSLDistro"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'"
    exit 1
}

# Create scheduled task for WSL keep-alive + service start
Write-Host "Creating scheduled task: HermesAutoStart" -ForegroundColor Yellow

$taskExists = Get-ScheduledTask -TaskName "HermesAutoStart" -ErrorAction SilentlyContinue
if ($taskExists) {
    Write-Host "Removing existing task..."
    Unregister-ScheduledTask -TaskName "HermesAutoStart" -Confirm:$false
}

# Task action: Keep WSL alive with sleep infinity + start service
$action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d $WSLDistro -u $WSLUser -- bash -c 'systemctl --user start hermes-ui; sleep infinity'"

# Task trigger: At logon
$trigger = New-ScheduledTaskTrigger -AtLogon

# Task settings: Run whether user is logged on or not, hidden
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden

# Register task as SYSTEM
Register-ScheduledTask -TaskName "HermesAutoStart" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force

Write-Host "Scheduled task created successfully" -ForegroundColor Green

# Create VBS keep-alive script in Startup folder
Write-Host ""
Write-Host "Creating VBS keep-alive script in Startup folder" -ForegroundColor Yellow

$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$vbsPath = "$startupFolder\keep_wsl_alive.vbs"

$vbsContent = @"
' Hermes WSL Keep-Alive Script
' Keeps WSL running in background without visible window

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl.exe -d $WSLDistro -u $WSLUser -- bash -c 'while true; do sleep 3600; done'", 0, False
"@

Set-Content -Path $vbsPath -Value $vbsContent -Encoding ASCII
Write-Host "VBS script created: $vbsPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "What happens now:" -ForegroundColor White
Write-Host "  1. Scheduled task 'HermesAutoStart' runs at Windows startup"
Write-Host "  2. VBS script in Startup folder keeps WSL alive"
Write-Host "  3. No black terminal window will appear"
Write-Host "  4. Web UI accessible at http://localhost:8648"
Write-Host ""
Write-Host "Test: Restart computer, wait 30-60 seconds, open browser to localhost:8648" -ForegroundColor Yellow
Write-Host ""
Write-Host "To verify service status in WSL:" -ForegroundColor White
Write-Host "  systemctl --user status hermes-ui.service"