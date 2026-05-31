#!/bin/bash
# install.sh — full install (toolchains + config setup) via profile

# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/modules/_lib/bootstrap.sh"

# if [ -d /mnt/c/Windows ] && ! cmd.exe /d /c 'openfiles > nul 2>nul'; then
# 	cmd.exe /d /c 'setx WSLENV USERNAME/u:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu'
# 	powershell.exe -Command "Start-Process -FilePath wsl -ArgumentList '-d','$WSL_DISTRO_NAME','-e','bash','$DOTFILES_DIR/$0' -Verb RunAs"
# 	exit 0
# fi

set -e
sudo -v

# Profile が install + setup を順次実行する
# if [ -d /mnt/c/Windows ]; then
# 	bash "$DOTFILES_DIR/profiles/host-wsl.sh"
# else
	PROFILE="$(dotfiles_profile)"
	bash "$DOTFILES_DIR/profiles/$PROFILE.sh"
# fi

read -p "Press any key to finish . . ."
