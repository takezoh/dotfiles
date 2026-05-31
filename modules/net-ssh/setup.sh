#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "net-ssh: setup"

mkdir -m 700 -p "$HOME/.ssh"
link net-ssh/ssh/config "$HOME/.ssh/config"
