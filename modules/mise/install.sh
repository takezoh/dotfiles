#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

if has_cmd mise; then
	log "mise: already installed"
	exit 0
fi

. "$MODULES_DIR/brew/env.sh"

if has_cmd brew; then
	brew_install mise
else
	log "mise: installing via curl"
	curl https://mise.run | sh
fi
