#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

has_cmd mise || { log "agent-codex: skip update (mise not installed)"; exit 0; }

log "agent-codex: update"
mise exec node -- npm install -g @openai/codex@latest
mise reshim
