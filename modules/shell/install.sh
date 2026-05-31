#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"

PKGS=(
	zsh
	starship
	atuin
	fzf
	zoxide
	glow
	tmux
	ripgrep
	bat
	neovim
)

brew_install "${PKGS[@]}"
