#!/usr/bin/env bash
# WSL → Windows 側 mklink 配置
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

is_wsl || { log "wsl-windows-bridge: skip (not WSL)"; exit 0; }

log "wsl-windows-bridge: setup"

cmd.exe /d /c rmdir /q /s '%USERPROFILE%\.ssh' || true
cmd.exe /d /c mklink /d '%USERPROFILE%\.ssh' "$(wslpath -aw "$HOME/.ssh")"

cmd.exe /d /c del /q '%USERPROFILE%\.gitconfig' || true
cmd.exe /d /c mklink '%USERPROFILE%\.gitconfig' "$(wslpath -aw "$MODULES_DIR/cli-git/gitconfig")"
