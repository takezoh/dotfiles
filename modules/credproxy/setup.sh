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
	# op が未サインインなら session を張る。desktop 連携が有効なら whoami 自体が
	# biometric で通り signin は不要。連携が無い環境では op signin の出力
	# (export OP_SESSION_...) を eval して以降の op read に効かせる。対話端末で
	# 実行していること・op account add 済みであることが前提。
	if ! op whoami >/dev/null 2>&1; then
		log "credproxy: op 未サインイン、op signin を実行します（認証プロンプトが出ます）"
		session="$(op signin 2>/dev/null || true)"
		[ -n "$session" ] && eval "$session"
		if ! op whoami >/dev/null 2>&1; then
			log "credproxy: WARN op signin に失敗（対話端末か、op account add 済みか確認）。SA token 取得をスキップ"
			return 0
		fi
	fi
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

# 親 env への鍵供給 snippet を login shell の per-host phase へ copy する。
# daemon の起動可否に依らず配置する — snippet は broker 不在なら何もしない。
# 鍵が増えてもこの snippet は不変 (broker の ROUTE_ENV だけが増える)。
# copy であって symlink にしない (working tree を実行経路に載せない規約)。
SHELLENV_DIR="$HOME/.local/config/zshrc"
mkdir -p "$SHELLENV_DIR"
cp "$ASSETS/shellenv/credproxy-env.sh" "$SHELLENV_DIR/50_credproxy-env.zsh"
log "credproxy: installed shell env supply -> $SHELLENV_DIR/50_credproxy-env.zsh"

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
