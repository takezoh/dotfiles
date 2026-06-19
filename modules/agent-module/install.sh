#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

# dotfiles と同階層の skills ディレクトリ（submodule ではなく別管理）
SKILLS_DIR="$(cd "$DOTFILES_DIR/.." && pwd -P)/skills"

if [ ! -d "$SKILLS_DIR" ]; then
	log "agent-module: $SKILLS_DIR が無いためスキップ"
	exit 0
fi

if [ -f "$SKILLS_DIR/install.sh" ]; then
	log "agent-module: install ($SKILLS_DIR)"
	bash "$SKILLS_DIR/install.sh"
fi
