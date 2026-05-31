#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/rust/env.sh"

has_cmd rustup || { log "rust: skip update (rustup not installed)"; exit 0; }

log "rust: update"
rustup update
