#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

# dotfiles と同階層の skills ディレクトリ（submodule ではなく別管理）
SKILLS_DIR="$(cd "$DOTFILES_DIR/.." && pwd -P)/skills"

if [ ! -d "$SKILLS_DIR" ]; then
	log "agent-skills: $SKILLS_DIR が無いためスキップ"
	exit 0
fi

if [ -f "$SKILLS_DIR/setup.sh" ]; then
	log "agent-skills: setup ($SKILLS_DIR)"
	bash "$SKILLS_DIR/setup.sh"
fi
