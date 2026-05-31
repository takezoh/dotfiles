@echo off
openfiles > nul 2>nul
if errorlevel 1 (
		powershell -Command Start-Process \"%~f0\" -Verb runas
		exit
)

powershell -NoProfile -ExecutionPolicy Unrestricted "%~dp0install-windows.ps1" -Verb runas
pause
