#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

if [ -x "$HOME/.cargo/bin/cargo" ]; then
	log "rust: already installed"
	exit 0
fi

log "rust: installing via rustup"
curl https://sh.rustup.rs -sSf | sh -s -- -y
