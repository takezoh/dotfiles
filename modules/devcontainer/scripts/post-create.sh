#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

# agent-module 配下のみ更新（apt/brew/mise/rust は重いため除外）
{
	script="$HOME/.dotfiles/modules/agent-module/update.sh"
	[ -f "$script" ] && bash "$script"
} > /tmp/post-create.log 2>&1 &
disown
