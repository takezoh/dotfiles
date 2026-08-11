#!/usr/bin/env bash
# credproxy: install the systemd user unit and enable the daemon — but only once
# a 1Password service-account token exists. Without the token the broker cannot
# resolve anything, so we install the unit and stop, leaving a clear next step.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
# 解決元は 2 経路 (op-resolve.py 参照): 事前解決 store か service-account token。
# どちらか一方があれば broker は仕事ができる。
TOKEN_STORE="$HOME/.secrets/op/service-account.token"
RESOLVED_STORE="$HOME/.secrets/credproxyd/resolved.json"

# macOS uses launchd, not systemd. Ship the launchd path in README go-live;
# do not attempt a systemd unit there.
if is_darwin; then
	log "credproxy: macOS は launchd 運用（README go-live 参照）。systemd unit はスキップ"
	exit 0
fi

if ! has_cmd systemctl || [ ! -d /run/systemd/system ]; then
	log "credproxy: systemd 未稼働のため unit 有効化をスキップ"
	exit 0
fi

mkdir -p "$UNIT_DIR"
cp "$ASSETS/credproxyd.service" "$UNIT_DIR/credproxyd.service"
systemctl --user daemon-reload
log "credproxy: installed systemd user unit"

if [ ! -f "$RESOLVED_STORE" ] && [ ! -f "$TOKEN_STORE" ]; then
	log "credproxy: 解決元が未設定（$RESOLVED_STORE も $TOKEN_STORE も無い）。daemon は起動しない"
	log "credproxy: go-live 手順は modules/credproxy/README.md を参照"
	exit 0
fi

systemctl --user enable --now credproxyd.service
log "credproxy: credproxyd enabled"
