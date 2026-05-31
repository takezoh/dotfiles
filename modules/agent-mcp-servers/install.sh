#!/usr/bin/env zsh
# Setup MCP servers (user scope)
#
# 前提:
#   - jq, claude CLI が必要
#   - MCP 登録には 1Password CLI (op) が必要
#   - notebooklm: 事前に init が必要 (スクリプト内コメント参照)
#
# === NotebookLM MCP の初期セットアップ ===
#   mkdir -p ~/.config/notebooklm-mcp
#   cd ~/.config/notebooklm-mcp
#   uvx notebooklm-mcp init -o ~/.config/notebooklm-mcp/notebooklm-config.json \
#     https://notebooklm.google.com/notebook/<NOTEBOOK_ID>
#   # ブラウザが開くので Google アカウントでログインする

set -euo pipefail

mcp_add() {
	local name="$1"
	shift
	if claude mcp get "$name" &>/dev/null; then
		echo "[skip]  $name (already registered)"
		return
	fi
	echo "[add]   $name"
	claude mcp add --scope user "$name" "$@"
}

# HTTP / SSE servers
mcp_add atlassian --transport sse  https://mcp.atlassian.com/v1/sse
mcp_add notion    --transport http https://mcp.notion.com/mcp

mcp_add filesystem        -- npx -y @modelcontextprotocol/server-filesystem

if ! claude mcp get "playwright" &>/dev/null; then
	npx -y playwright install --with-deps chrome
	mcp_add playwright        -- npx -y @playwright/mcp@latest
fi
mcp_add context7            -- npx -y @upstash/context7-mcp@latest

mcp_add codex -- codex mcp-server

echo ""
echo "Done. Run 'claude mcp list' to verify."
