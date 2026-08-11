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
TOKEN_STORE="${CREDPROXY_OP_TOKEN_FILE:-$HOME/.secrets/op/service-account.token}"
RESOLVED_STORE="${CREDPROXY_RESOLVED_STORE:-$HOME/.secrets/credproxyd/resolved.json}"
# service-account token itself は 1Password の Personal item に保管し、setup 時に
# 対話 op (op.exe は Personal を読める。SA token は Personal を読めない) で取得して
# token file に落とす。daemon の native op はこの token で scoped vault を読む。
SA_TOKEN_REF="${CREDPROXY_SA_TOKEN_REF:-op://Personal/4h3467uq736jjlju6xkeu6uvyq/credential}"

# --- service-account token を 1Password から provision (無ければ) ---
# 既存の token は上書きしない (rotation は rm + 再実行、または 1Password 側で
# item を更新して rm + 再実行)。op 未サインイン等の失敗は warn に留める。
provision_sa_token() {
	[ -f "$TOKEN_STORE" ] && return 0
	[ -n "$SA_TOKEN_REF" ] || return 0
	has_cmd op || { log "credproxy: op 不在のため SA token を取得できない（手動配置か対話 shell で再実行）"; return 0; }
	mkdir -p "$(dirname "$TOKEN_STORE")"
	chmod 700 "$(dirname "$TOKEN_STORE")" 2>/dev/null || true
	tmp="$TOKEN_STORE.tmp.$$"
	if ( umask 077; op read --no-newline "$SA_TOKEN_REF" >"$tmp" 2>/dev/null ) && [ -s "$tmp" ]; then
		chmod 600 "$tmp"
		mv "$tmp" "$TOKEN_STORE"
		log "credproxy: service-account token を 1Password ($SA_TOKEN_REF) から取得して配置"
	else
		rm -f "$tmp"
		log "credproxy: WARN op で SA token を取得できず（op 未サインインか ref 誤り）。$SA_TOKEN_REF を確認"
	fi
}

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

provision_sa_token

if [ ! -f "$RESOLVED_STORE" ] && [ ! -f "$TOKEN_STORE" ]; then
	log "credproxy: 解決元が未設定（$RESOLVED_STORE も $TOKEN_STORE も無い）。daemon は起動しない"
	log "credproxy: go-live 手順は modules/credproxy/README.md を参照"
	exit 0
fi

systemctl --user enable credproxyd.service
if systemctl --user is-active --quiet credproxyd.service; then
	# 既に稼働中なら restart — token 差し替え時に daemon の解決キャッシュを捨てて
	# 新しい値を確実に反映させる (credproxyd は expires_in_sec-30 秒キャッシュする)。
	systemctl --user restart credproxyd.service
	log "credproxy: credproxyd restarted (cache cleared)"
else
	systemctl --user start credproxyd.service
	log "credproxy: credproxyd started"
fi
