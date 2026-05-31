#!/bin/bash
# update.sh — update installed toolchains & agents (no install/symlink)
# 完全インストールは install.sh、symlink 設定は setup.sh を使用

# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/modules/_lib/bootstrap.sh"

set -e
sudo -v

PROFILE="$(dotfiles_profile)"
PHASE=update bash "$DOTFILES_DIR/profiles/$PROFILE.sh"

read -p "Press any key to finish . . ."
