#!/usr/bin/env zsh
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-codex: setup"

CODEX_DIR="$HOME/.codex"
MANAGED_CONFIG="$MODULES_DIR/agent-codex/codex/config.toml"
CODEX_CONFIG="$CODEX_DIR/config.toml"
# AGENTS.md の symlink は skills リポの setup が担当する
MERGE_APPEND="$MODULES_DIR/_lib/merge_append.py"
ROOST_BIN="/workspace/agent-roost/roost"

mkdir -p "$CODEX_DIR"

# config.toml
UPDATED_CONFIG=$("$MERGE_APPEND" toml "$MANAGED_CONFIG" "$CODEX_CONFIG")
printf '%s\n' "$UPDATED_CONFIG" > "$CODEX_CONFIG"
echo "Updated: $CODEX_CONFIG"

# hooks.json
printf '%s\n' "$(cat "$MODULES_DIR/agent-codex/codex/hooks.json")" > "$CODEX_DIR/hooks.json"
echo "Initialized: $CODEX_DIR/hooks.json"

if [ -x "$ROOST_BIN" ]; then
	"$ROOST_BIN" codex setup
fi
