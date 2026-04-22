' Hermes WSL Keep-Alive Script
' This script keeps WSL running in background without any visible window
' Place in: C:\Users\<username>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl.exe -d %WSL_DISTRO% -u %WSL_USER% -- bash -c 'while true; do sleep 3600; done'", 0, False