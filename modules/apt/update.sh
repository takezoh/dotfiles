#!/bin/bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

is_linux || { log "apt: skip update (not linux)"; exit 0; }

log "apt: update"
export DEBIAN_FRONTEND=noninteractive
as_root apt-get update -q
as_root apt-get upgrade -y
as_root apt-get autoremove -y
