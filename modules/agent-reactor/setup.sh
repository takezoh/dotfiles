#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-reactor: setup"

link agent-reactor/settings.toml "$HOME/.agent-reactor/settings.toml"
