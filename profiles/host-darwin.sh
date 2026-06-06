#!/usr/bin/env bash
# profiles/host-darwin.sh — host machine (macOS, full)
set -euo pipefail

modules=(
	brew
	mise
	rust
	sdk-go
	sdk-node
	sdk-python
	sdk-ruby
	sdk-java
	cli-gcloud
	shell
	editor-nvim
	cli
	roost
	agent-claude
	agent-mcp-servers
	agent-claude-lsp
	agent-codex
	agent-gemini
	agent-skills
	terminal-wezterm
	net-ssh
	macos-defaults
	devcontainer
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
