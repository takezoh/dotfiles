#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-gemini: install"
has_cmd gemini || mise exec node -- npm install -g @google/gemini-cli
mise reshim
