#!/usr/bin/env zsh
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-gemini: setup"

GEMINI_DIR="$HOME/.gemini"
SETTINGS="$GEMINI_DIR/settings.json"
MANAGED_SETTINGS="$MODULES_DIR/agent-gemini/gemini/settings.json"
# AGENTS.md の symlink は skills リポの setup が担当する
MERGE_APPEND="$MODULES_DIR/_lib/merge_append.py"
ROOST_BIN="/workspace/agent-roost/roost"

mkdir -p "$GEMINI_DIR"

rm -f "$GEMINI_DIR/GEMINI.md"

UPDATED=$("$MERGE_APPEND" json "$MANAGED_SETTINGS" "$SETTINGS")
UPDATED=$(printf '%s\n' "$UPDATED" | jq --slurpfile managed "$MANAGED_SETTINGS" '.hooks = (($managed[0].hooks // {}))')
printf '%s\n' "$UPDATED" > "$SETTINGS"
echo "Updated: $SETTINGS"

if [ -x "$ROOST_BIN" ]; then
	"$ROOST_BIN" gemini setup
fi
