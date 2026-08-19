#!/usr/bin/env bash
# 1Passwordを正本としてservice-account tokenを一度だけ取得し、
# local secret boundaryへowner-onlyでatomicに配置する。
set -euo pipefail
umask 077

readonly SECRET_ROOT="$HOME/.secrets"
readonly TOKEN_DIR="$SECRET_ROOT/op"
readonly TOKEN_STORE="$TOKEN_DIR/service-account.token"
readonly SA_TOKEN_REF="op://Personal/4h3467uq736jjlju6xkeu6uvyq/credential"
readonly NATIVE_OP_BIN="/usr/local/bin/op"
readonly TRUSTED_BIN_UID=0
readonly WSL_MARKER="/mnt/c/Windows"

log() {
	printf '%s\n' "$*" >&2
}

file_mode() {
	stat -c '%a' "$1"
}

file_uid() {
	stat -c '%u' "$1"
}

owned_directory() {
	[ -d "$1" ] && [ ! -L "$1" ] && [ "$(file_uid "$1")" = "$(id -u)" ] \
		&& [ "$(file_mode "$1")" = 700 ]
}

token_ready() {
	[ -f "$TOKEN_STORE" ] && [ ! -L "$TOKEN_STORE" ] && [ -s "$TOKEN_STORE" ] \
		&& [ "$(file_uid "$TOKEN_STORE")" = "$(id -u)" ] \
		&& [ "$(file_mode "$TOKEN_STORE")" = 600 ]
}

resolve_interactive_op() {
	local candidate
	if [ -d "$WSL_MARKER" ]; then
		candidate="$(command -v op 2>/dev/null || true)"
		[ -n "$candidate" ] || return 1
		[ -f "$candidate" ] && [ ! -L "$candidate" ] && [ -x "$candidate" ] || return 1
		printf '%s\n' op
		return 0
	fi
	[ -f "$NATIVE_OP_BIN" ] && [ ! -L "$NATIVE_OP_BIN" ] && [ -x "$NATIVE_OP_BIN" ] \
		&& [ "$(file_uid "$NATIVE_OP_BIN")" = "$TRUSTED_BIN_UID" ] || return 1
	printf '%s\n' "$NATIVE_OP_BIN"
}

refresh=0
case "${1:-}" in
	"") ;;
	--refresh) refresh=1 ;;
	*)
		log "usage: provision-service-account-token.sh [--refresh]"
		exit 64
		;;
esac

token_exists=0
if [ -e "$TOKEN_STORE" ] || [ -L "$TOKEN_STORE" ]; then
	token_exists=1
	if ! token_ready; then
		log "credproxy: conflicting (service-account token identity or mode invalid); route disabled"
		exit 2
	fi
fi

for directory in "$SECRET_ROOT" "$TOKEN_DIR"; do
	if [ -e "$directory" ] || [ -L "$directory" ]; then
		if ! owned_directory "$directory"; then
			log "credproxy: conflicting (protected secret directory identity invalid); route disabled"
			exit 2
		fi
	else
		mkdir -p "$directory"
	fi
	chmod 0700 "$directory"
done

if [ "$token_exists" -eq 1 ] && [ "$refresh" -eq 0 ]; then
	log "credproxy: protected service-account token already present"
	exit 0
fi

if ! interactive_op="$(resolve_interactive_op)"; then
	log "credproxy: credential_source_unavailable (interactive 1Password CLI unavailable); route disabled"
	exit 3
fi

tmp="$(mktemp "$TOKEN_DIR/.service-account.token.XXXXXX")"
cleanup() {
	rm -f "$tmp"
}
trap cleanup EXIT HUP INT TERM
if ! "$interactive_op" read --no-newline "$SA_TOKEN_REF" >"$tmp"; then
	log "credproxy: credential_source_unavailable (1Password service-account token read failed); route disabled"
	exit 3
fi
if [ ! -f "$tmp" ] || [ -L "$tmp" ] || [ ! -s "$tmp" ]; then
	log "credproxy: credential_source_unavailable (1Password returned an empty token); route disabled"
	exit 3
fi
chmod 0600 "$tmp"
mv "$tmp" "$TOKEN_STORE"
trap - EXIT HUP INT TERM
log "credproxy: protected service-account token provisioned from 1Password"
