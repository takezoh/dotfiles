#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "terminal-wezterm: setup"

link terminal-wezterm/wezterm "$HOME/.config/wezterm"
