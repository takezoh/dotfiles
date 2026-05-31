#!/bin/bash
# Windows toast notification utility for WSL2

if ! grep -qi microsoft /proc/version 2>/dev/null; then
	exit 0
fi

TITLE="${1:-Claude Code}"
BODY="${2:-Notification}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WINPATH=$(wslpath -w "$SCRIPT_DIR/notify-windows.ps1")

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WINPATH" -Title "$TITLE" -Body "$BODY" 2>/dev/null

exit 0
