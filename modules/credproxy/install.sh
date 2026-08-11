#!/usr/bin/env bash
# credproxy: build the broker binaries, install a native headless `op`, and lay
# down config/hooks/wrappers as copies. Inert until a 1Password service-account
# token is provisioned (see README go-live). Never overwrites an existing
# user config or token.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
CREDPROXY_SRC="$(cd "$DOTFILES_DIR/.." && pwd -P)/credproxy"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/credproxyd"

# 1. Build credproxy + credproxyd from the sibling repo (skip if go/repo absent).
if [ ! -d "$CREDPROXY_SRC" ]; then
	log "credproxy: source repo not found at $CREDPROXY_SRC, skipping build"
elif ! has_cmd go; then
	log "credproxy: go 未導入のためビルドをスキップ"
else
	mkdir -p "$BIN_DIR"
	log "credproxy: building credproxy + credproxyd -> $BIN_DIR"
	( cd "$CREDPROXY_SRC" && go build -o "$BIN_DIR/credproxyd" ./cmd/credproxyd )
	( cd "$CREDPROXY_SRC" && go build -o "$BIN_DIR/credproxy" ./cmd/credproxy )
fi

# 2. Native headless `op` (Linux only). The WSL `op` on PATH is the op.exe shim
#    (interactive); the broker needs a native binary it can run non-interactively.
OP_BIN="/usr/local/bin/op"
if is_linux && [ ! -x "$OP_BIN" ]; then
	OP_VERSION="v2.31.1"
	case "$(uname -m)" in
		x86_64)  OP_ARCH="amd64" ;;
		aarch64) OP_ARCH="arm64" ;;
		*)       OP_ARCH="" ;;
	esac
	if [ -z "$OP_ARCH" ]; then
		log "credproxy: unsupported arch for native op, skipping"
	else
		TMP="$(mktemp -d)"
		trap 'rm -rf "$TMP"' EXIT
		URL="https://cache.agilebits.com/dist/1P/op2/pkg/${OP_VERSION}/op_linux_${OP_ARCH}_${OP_VERSION}.zip"
		log "credproxy: installing native op ${OP_VERSION} (${OP_ARCH}) -> $OP_BIN"
		if curl -fsSL "$URL" -o "$TMP/op.zip"; then
			( cd "$TMP" && unzip -qo op.zip )
			# 非対話 (sudo password 不可) でも asset 配置まで進めるため、失敗は
			# warn に留める。root 所有 /usr/local/bin/op は confused-deputy 対策
			# なので user パスへは fallback しない — 後で人間が入れ直す。
			if ! as_root install -m 0755 "$TMP/op" "$OP_BIN" 2>/dev/null; then
				log "credproxy: WARN native op の配置に sudo が必要 — 対話 shell で install.sh を再実行する"
			fi
		else
			log "credproxy: WARN native op のダウンロード失敗（後で手動導入）"
		fi
	fi
fi

# 3. Config / hooks / wrappers — copy (never symlink: the source lives in a
#    sandbox-writable repo; the runtime assets must sit outside the agent's
#    reach). Do not overwrite an existing config.
mkdir -p "$CONFIG_DIR/hooks" "$CONFIG_DIR/wrappers"
if [ -f "$CONFIG_DIR/config.toml" ]; then
	log "credproxy: config.toml 既存のため保持"
else
	cp "$ASSETS/config.toml" "$CONFIG_DIR/config.toml"
	chmod 0600 "$CONFIG_DIR/config.toml"
	log "credproxy: installed config.toml"
fi
cp "$ASSETS/hooks/op-resolve.py" "$CONFIG_DIR/hooks/op-resolve.py"
chmod 0755 "$CONFIG_DIR/hooks/op-resolve.py"
cp "$ASSETS/wrappers/ctx-sync" "$CONFIG_DIR/wrappers/ctx-sync"
chmod 0755 "$CONFIG_DIR/wrappers/ctx-sync"
log "credproxy: hooks/wrappers refreshed"

log "credproxy: install done (daemon は setup で有効化。token 未設定なら inert)"
