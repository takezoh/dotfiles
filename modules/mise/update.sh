#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

has_cmd mise || { log "mise: skip update (not installed)"; exit 0; }

log "mise: update"
# brew 管理下では self-update 不可 — 本体更新は brew/update.sh が担う
mise self-update -y >/dev/null 2>&1 || log "mise: self-update skipped (brew-managed)"
mise upgrade
