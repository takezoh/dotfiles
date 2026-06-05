#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

# agent-* のみ更新（apt/brew/mise/rust は重いため除外）
{
	for m in agent-claude agent-codex agent-gemini; do
		script="$HOME/.dotfiles/modules/$m/update.sh"
		[ -f "$script" ] && bash "$script"
	done
} > /tmp/post-create.log 2>&1 &
disown
