#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "shell: setup"

mkdir -p "$HOME/.local/share/zsh"

link shell/zsh           "$HOME/.config/zsh"
link shell/zsh/.zshenv   "$HOME/.zshenv"
link shell/zsh/.zprofile "$HOME/.zprofile"
link shell/tmux.conf     "$HOME/.tmux.conf"
link shell/screenrc      "$HOME/.screenrc"
link shell/inputrc       "$HOME/.inputrc"

# ログインシェルを zsh にする（passwd 上の login shell）。
# ターミナル側の zsh 直接起動に依存せず $SHELL も zsh を指すようにする。
ZSH_BIN=/usr/bin/zsh
ZSH_USER=$(id -un)
if [ ! -x "$ZSH_BIN" ]; then
	log "shell: $ZSH_BIN が無いため login shell 変更をスキップ"
elif [ "$(getent passwd "$ZSH_USER" | cut -d: -f7)" = "$ZSH_BIN" ]; then
	log "shell: login shell は既に $ZSH_BIN"
elif as_root chsh -s "$ZSH_BIN" "$ZSH_USER"; then
	log "shell: login shell を $ZSH_BIN に変更（反映には wsl --shutdown 等が必要）"
else
	log "shell: login shell の変更に失敗。手動で 'chsh -s $ZSH_BIN' を実行してください"
fi
