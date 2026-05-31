#!/bin/bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"

brew_cmd --version >/dev/null 2>&1 || { log "brew: skip update (not installed)"; exit 0; }

log "brew: update"
brew_cmd update
brew_cmd upgrade
brew_cmd cleanup
