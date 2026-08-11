#!/usr/bin/env bash
# credproxy: install the systemd user unit and enable the daemon — but only once
# a 1Password service-account token exists. Without the token the broker cannot
# resolve anything, so we install the unit and stop, leaving a clear next step.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
TOKEN_STORE="$HOME/.secrets/op/service-account.token"

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

if [ ! -f "$TOKEN_STORE" ]; then
	log "credproxy: service-account token 未設定（$TOKEN_STORE）。daemon は起動しない"
	log "credproxy: go-live 手順は modules/credproxy/README.md を参照"
	exit 0
fi

systemctl --user enable --now credproxyd.service
log "credproxy: credproxyd enabled"
