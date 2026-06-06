#!/usr/bin/env bash
# profiles/devcontainer.sh — devcontainer (linux, subset)
set -euo pipefail

modules=(
	apt
	brew
	mise
	rust
	sdk-go
	sdk-node
	sdk-python
	cli-gcloud
	shell
	editor-nvim
	cli
	agent-claude
	agent-mcp-servers
	agent-codex
	agent-gemini
	agent-skills
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
