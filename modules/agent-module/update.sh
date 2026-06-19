#!/usr/bin/env bash
# Thin entry point — defer update to the external agent-module repository.
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

AGENT_MODULE_DIR="$(cd "$DOTFILES_DIR/.." && pwd -P)/agent-module"

if [ ! -d "$AGENT_MODULE_DIR" ]; then
	log "agent-module: $AGENT_MODULE_DIR が無いためスキップ"
	exit 0
fi

log "agent-module: update ($AGENT_MODULE_DIR)"
export DOTFILES_DIR AGENT_MODULE_DIR
PHASE=update bash "$AGENT_MODULE_DIR/profiles/$(dotfiles_profile).sh"
