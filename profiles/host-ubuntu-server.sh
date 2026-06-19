#!/usr/bin/env bash
# profiles/host-ubuntu-server.sh — ubuntu server (linux, headless subset)
set -euo pipefail

modules=(
	apt
	brew
	mise
	rust
	sdk-go
	sdk-node
	sdk-python
	shell
	editor-nvim
	cli
	docker
	agent-reactor
	agent-claude
	agent-mcp-servers
	agent-codex
	agent-gemini
	agent-module
	devcontainer
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
