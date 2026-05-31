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
	vcs-git
	vcs-tig
	cli
	docker
	agent-claude
	agent-codex
	agent-gemini
	agent-shared
	agent-skills
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
