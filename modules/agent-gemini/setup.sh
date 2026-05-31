#!/usr/bin/env zsh
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-gemini: setup"

GEMINI_DIR="$HOME/.gemini"
SETTINGS="$GEMINI_DIR/settings.json"
MANAGED_SETTINGS="$MODULES_DIR/agent-gemini/gemini/settings.json"
AGENTS_MD_SOURCE="$MODULES_DIR/agent-shared/AGENTS.md"
MERGE_APPEND="$MODULES_DIR/_lib/merge_append.py"
ROOST_BIN="/workspace/agent-roost/roost"

mkdir -p "$GEMINI_DIR"

# AGENTS.md
ln -sf "$AGENTS_MD_SOURCE" "$GEMINI_DIR/AGENTS.md"
echo "Linked: $GEMINI_DIR/AGENTS.md -> $AGENTS_MD_SOURCE"
rm -f "$GEMINI_DIR/GEMINI.md"

UPDATED=$("$MERGE_APPEND" json "$MANAGED_SETTINGS" "$SETTINGS")
UPDATED=$(printf '%s\n' "$UPDATED" | jq --slurpfile managed "$MANAGED_SETTINGS" '.hooks = (($managed[0].hooks // {}))')
printf '%s\n' "$UPDATED" > "$SETTINGS"
echo "Updated: $SETTINGS"

if [ -x "$ROOST_BIN" ]; then
	"$ROOST_BIN" gemini setup
fi
