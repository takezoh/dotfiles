. "$DOTFILES_DIR/modules/brew/env.sh"
. "$DOTFILES_DIR/modules/mise/env.sh"

# roost hostexec のシムを brew/mise 由来のバイナリ(gh 等)より優先させる。
# /opt/roost/run/hostexec-shims はコンテナ内にのみ存在するためホストでは no-op。
[[ -d /opt/roost/run/hostexec-shims ]] && path=(/opt/roost/run/hostexec-shims ${path:#/opt/roost/run/hostexec-shims})
