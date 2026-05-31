#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"

log "agent-claude: install"

# yq/jq は setup.sh の settings.yaml→JSON マージで必須
brew_install socat bubblewrap yq jq

# Claude Code CLI 本体（公式 native installer）
has_cmd claude || curl -fsSL https://claude.ai/install.sh | bash
