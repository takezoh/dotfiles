#!/bin/bash
# dotfiles.sh — symlink-only setup (no install)
# 完全インストールは install.sh を使用

# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/modules/_lib/bootstrap.sh"

# if [ -d /mnt/c/Windows ] && ! cmd.exe /d /c 'openfiles > nul 2>nul'; then
# 	cmd.exe /d /c 'setx WSLENV USERNAME/u:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu'
# 	powershell.exe -Command "Start-Process -FilePath wsl -ArgumentList '-d','$WSL_DISTRO_NAME','-e','bash','$DOTFILES_DIR/$0' -Verb RunAs"
# 	exit 0
# fi

set -e

# Setup phase only (symlinks). Profile が wsl-windows-bridge も含めて処理する。
# if [ -d /mnt/c/Windows ]; then
# 	PHASE=setup bash "$DOTFILES_DIR/profiles/host-wsl.sh"
# else
	PROFILE="$(dotfiles_profile)"
	PHASE=setup bash "$DOTFILES_DIR/profiles/$PROFILE.sh"
# fi

read -p "Press any key to finish . . ."
