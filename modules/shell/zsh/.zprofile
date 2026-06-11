. "$DOTFILES_DIR/modules/brew/env.sh"
. "$DOTFILES_DIR/modules/mise/env.sh"

# agent-reactor hostexec のシムを brew/mise 由来のバイナリ(gh 等)より優先させる。
# /opt/agent-reactor/run/hostexec-shims はコンテナ内にのみ存在するためホストでは no-op。
[[ -d /opt/agent-reactor/run/hostexec-shims ]] && path=(/opt/agent-reactor/run/hostexec-shims ${path:#/opt/agent-reactor/run/hostexec-shims})
