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
	cli-git
	cli-tig
	cli
	agent-claude
	agent-codex
	agent-gemini
	agent-shared
	agent-skills
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
