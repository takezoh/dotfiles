#!/usr/bin/env sh
# dotfiles が所有する platform-specific broker socket contract。
broker_socket_path() {
	uid="$(id -u)"
	if is_darwin; then
		printf '%s\n' "$HOME/Library/Caches/credproxyd/runtime/credproxyd/broker.sock"
	else
		runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$uid}"
		printf '%s\n' "$runtime_dir/credproxyd/broker.sock"
	fi
}
