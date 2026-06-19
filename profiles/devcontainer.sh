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
)
# 注: agent-module は devcontainer では Dockerfile が各ステージ末尾で
# agent-module/profiles/devcontainer.sh を直接呼ぶため、ここからは外す
# (シム本体は host-* profile から引き続き使われる)。

PHASE="${PHASE:-${1:-all}}"
. "$(dirname "$0")/_run.sh"
