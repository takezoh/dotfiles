#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

# Install Homebrew / Linuxbrew if missing
if is_linux && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
	log "Installing Linuxbrew"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif is_darwin && ! has_cmd brew; then
	log "Installing Homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

. "$MODULES_DIR/brew/env.sh"

brew_cmd update
