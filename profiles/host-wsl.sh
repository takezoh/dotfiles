#!/usr/bin/env bash
# profiles/host-wsl.sh — host machine (WSL/linux, full)
set -euo pipefail

modules=(
	apt
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
	android-re
	agent-module
	terminal-windows
	terminal-wezterm
	net-ssh
	# wsl-windows-bridge
)

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
