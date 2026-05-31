#!/usr/bin/env bash
# Symlink ~/.devcontainer → modules/devcontainer/
# VS Code Dev Containers 拡張等が ~/.devcontainer/devcontainer.json を参照する想定
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "devcontainer: setup"

DEVCONTAINER_SRC="$MODULES_DIR/devcontainer"
DEVCONTAINER_DST="$HOME/.devcontainer"

if [ ! -L "$DEVCONTAINER_DST" ] && [ -d "$DEVCONTAINER_DST" ]; then
	log "backup: $DEVCONTAINER_DST -> ${DEVCONTAINER_DST}.bak"
	mv "$DEVCONTAINER_DST" "${DEVCONTAINER_DST}.bak"
fi

ln -sfn "$DEVCONTAINER_SRC" "$DEVCONTAINER_DST"
log "linked: $DEVCONTAINER_DST -> $DEVCONTAINER_SRC"
