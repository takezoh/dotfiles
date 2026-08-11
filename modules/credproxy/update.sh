#!/usr/bin/env bash
# credproxy: rebuild the broker binaries from the sibling repo and restart the
# daemon if it is running. Config/hooks/wrappers are refreshed by install.sh.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

CREDPROXY_SRC="$(cd "$DOTFILES_DIR/.." && pwd -P)/credproxy"
BIN_DIR="$HOME/.local/bin"

if [ ! -d "$CREDPROXY_SRC" ]; then
	log "credproxy: source repo not found at $CREDPROXY_SRC, skipping"
	exit 0
fi
if ! has_cmd go; then
	log "credproxy: go 未導入のため rebuild をスキップ"
	exit 0
fi

mkdir -p "$BIN_DIR"
log "credproxy: rebuilding binaries"
( cd "$CREDPROXY_SRC" && go build -o "$BIN_DIR/credproxyd" ./cmd/credproxyd )
( cd "$CREDPROXY_SRC" && go build -o "$BIN_DIR/credproxy" ./cmd/credproxy )

if has_cmd systemctl && [ -d /run/systemd/system ] \
	&& systemctl --user is-active --quiet credproxyd.service; then
	log "credproxy: restarting credproxyd"
	systemctl --user restart credproxyd.service
fi
