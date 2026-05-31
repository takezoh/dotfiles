#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

is_darwin || { log "macos-defaults: skip (not darwin)"; exit 0; }

log "macos-defaults: setup"

defaults write com.apple.finder AppleShowAllFiles TRUE
defaults write com.apple.desktopservices DSDontWriteNetworkStores TRUE
killall Finder
