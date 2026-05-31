#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

has_cmd claude || { log "agent-claude: skip update (not installed)"; exit 0; }

log "agent-claude: update"
claude update
claude plugin marketplace update >/dev/null 2>&1 || true
