#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "cli: setup"

link cli/atuin     "$HOME/.config/atuin"
link cli/bat       "$HOME/.config/bat"
link cli/direnv    "$HOME/.config/direnv"
link cli/ripgrep   "$HOME/.config/ripgrep"
link cli/ripsearch "$HOME/.config/ripsearch"
link cli/starship.toml "$HOME/.config/starship.toml"
