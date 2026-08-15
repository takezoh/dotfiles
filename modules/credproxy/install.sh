#!/usr/bin/env bash
# credproxy: obtain/build the broker binaries, install a native headless `op`,
# and lay down config/hooks/wrappers as copies. Credential provisioning is owned
# by setup and is limited to the protected ~/.secrets boundary.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
. "$(cd "$(dirname "$0")" && pwd)/socket-path.sh"
CREDPROXY_SRC="$(cd "$DOTFILES_DIR/.." && pwd -P)/credproxy"
readonly CREDPROXY_REPOSITORY="https://github.com/takezoh/credproxy.git"
readonly CREDPROXY_BOOTSTRAP_REVISION="cbe0d235e4412d12b01f7cdbcaa5577ad2595313"
RUNTIME_ROOT="$HOME/.local/lib/credproxy"
BIN_DIR="$RUNTIME_ROOT/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/credproxyd"
HOOK_DIR="$RUNTIME_ROOT/hooks"
BINDING_DIR="$RUNTIME_ROOT/bindings"
MINUET_CLIENT="$BIN_DIR/minuet-anthropic"
MINUET_BINDING="$BINDING_DIR/minuet-anthropic.json"
CONFIG_PATH="$CONFIG_DIR/config.toml"
CONFIG_PROVENANCE="$CONFIG_DIR/config.toml.managed.json"
# Last dotfiles-managed config before closed-operation routing.  It may be
# migrated only when the installed bytes are this exact known revision.
readonly LEGACY_CONFIG_SHA256="4233fb7a99556dce594897ac35111ffcf987399fdb6fad4f357533e724013989"
readonly ORIGINAL_MANAGED_CONFIG_SHA256="fea0d45dc40287b7df116025468a06bd7265677ae8abbe290a3809e3b185ef9b"

file_sha256() {
	if has_cmd sha256sum; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

file_mode() {
	if stat -c '%a' "$1" >/dev/null 2>&1; then
		stat -c '%a' "$1"
	else
		stat -f '%Lp' "$1"
	fi
}

file_uid() {
	if stat -c '%u' "$1" >/dev/null 2>&1; then
		stat -c '%u' "$1"
	else
		stat -f '%u' "$1"
	fi
}

resolved_regular_copy() {
	[ -f "$1" ] && [ ! -L "$1" ] && [ -x "$1" ]
}

sed_replacement() {
	printf '%s' "$1" | sed 's/[|&]/\\&/g'
}

write_config_provenance() {
	local revision="$1" template_revision="$2" tmp
	tmp="$(mktemp "$CONFIG_DIR/.config.toml.managed.XXXXXX")"
	/usr/bin/python3 - "$tmp" "$revision" "$template_revision" <<'PY'
import json, os, sys
path, revision, template_revision = sys.argv[1:]
payload = {
    "schema": "credproxy-managed-config/v1",
    "owner": "dotfiles:modules/credproxy",
    "source_revision": f"sha256:{revision}",
    "installed_revision": f"sha256:{revision}",
    "template_revision": f"sha256:{template_revision}",
}
with open(path, "w", encoding="utf-8") as stream:
    json.dump(payload, stream, sort_keys=True)
    stream.write("\n")
os.chmod(path, 0o600)
PY
	mv "$tmp" "$CONFIG_PROVENANCE"
}

install_managed_config() {
	local source_sha template_sha installed_sha rendered tmp provenance_state
	tmp="$(mktemp "$CONFIG_DIR/.config.toml.rendered.XXXXXX")"
	sed \
		-e "s|@BROKER_SOCKET@|$(sed_replacement "$(broker_socket_path)")|g" \
		-e "s|@HOOK_PATH@|$(sed_replacement "$HOOK_DIR/op-resolve.py")|g" \
		"$ASSETS/config.toml" >"$tmp"
	chmod 0600 "$tmp"
	rendered="$tmp"
	source_sha="$(file_sha256 "$rendered")"
	template_sha="$(file_sha256 "$ASSETS/config.toml")"
	if [ ! -e "$CONFIG_PATH" ] && [ ! -L "$CONFIG_PATH" ]; then
		mv "$rendered" "$CONFIG_PATH"
		write_config_provenance "$source_sha" "$template_sha"
		log "credproxy: installed managed config.toml"
		return 0
	fi
	if [ ! -f "$CONFIG_PATH" ] || [ -L "$CONFIG_PATH" ]; then
		log "credproxy: conflicting (installed config provenance unknown); daemon remains disabled"
		return 2
	fi
	installed_sha="$(file_sha256 "$CONFIG_PATH")"
	if [ "$installed_sha" = "$source_sha" ]; then
		rm -f "$rendered"
		if [ -f "$CONFIG_PROVENANCE" ] && [ ! -L "$CONFIG_PROVENANCE" ] \
			&& /usr/bin/python3 - "$CONFIG_PROVENANCE" "$source_sha" "$template_sha" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        value = json.load(stream)
except (OSError, UnicodeError, json.JSONDecodeError):
    raise SystemExit(1)
revision, template = sys.argv[2:]
expected = {
    "schema": "credproxy-managed-config/v1", "owner": "dotfiles:modules/credproxy",
    "source_revision": f"sha256:{revision}", "installed_revision": f"sha256:{revision}",
    "template_revision": f"sha256:{template}",
}
raise SystemExit(value != expected)
PY
		then
			chmod 0600 "$CONFIG_PATH"
			log "credproxy: managed config.toml revision verified"
			return 0
		fi
		log "credproxy: conflicting (installed config exact bytes but provenance absent/invalid); daemon remains disabled"
		return 2
	fi
	if [ -f "$CONFIG_PROVENANCE" ] && [ ! -L "$CONFIG_PROVENANCE" ] \
		&& /usr/bin/python3 - "$CONFIG_PROVENANCE" "$installed_sha" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        value = json.load(stream)
except (OSError, UnicodeError, json.JSONDecodeError):
    raise SystemExit(1)
installed = f"sha256:{sys.argv[2]}"
expected = {
    "schema": "credproxy-managed-config/v1",
    "owner": "dotfiles:modules/credproxy",
    "source_revision": installed,
    "installed_revision": installed,
}
raise SystemExit(any(value.get(key) != expected_value for key, expected_value in expected.items()))
PY
	then
		mv "$rendered" "$CONFIG_PATH"
		write_config_provenance "$source_sha" "$template_sha"
		log "credproxy: upgraded exact unmodified managed config.toml"
		return 0
	fi
	if [ "$installed_sha" = "$LEGACY_CONFIG_SHA256" ] || [ "$installed_sha" = "$ORIGINAL_MANAGED_CONFIG_SHA256" ]; then
		mv "$rendered" "$CONFIG_PATH"
		write_config_provenance "$source_sha" "$template_sha"
		log "credproxy: migrated exact known managed config.toml revision"
		return 0
	fi
	rm -f "$rendered"
	if [ -f "$CONFIG_PROVENANCE" ] && [ ! -L "$CONFIG_PROVENANCE" ]; then
		provenance_state="$(/usr/bin/python3 - "$CONFIG_PROVENANCE" "$installed_sha" "$template_sha" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        value = json.load(stream)
except (OSError, UnicodeError, json.JSONDecodeError):
    print("invalid")
    raise SystemExit
installed, template = sys.argv[2:]
if value.get("schema") != "credproxy-managed-config/v1" or value.get("owner") != "dotfiles:modules/credproxy":
    print("invalid")
elif value.get("installed_revision") != f"sha256:{installed}":
    print("modified")
elif value.get("template_revision") != f"sha256:{template}":
    print("source-new-installed-old")
else:
    print("unknown")
PY
)"
	else
		provenance_state="unknown"
	fi
	log "credproxy: conflicting (installed config $provenance_state); daemon remains disabled"
	return 2
}

install_minuet_binding_manifest() {
	local dotfiles_revision uid tmp
	install -m 0755 "$ASSETS/wrappers/minuet-anthropic" "$MINUET_CLIENT"
	uid="$(id -u)"
	if has_cmd git && git -C "$DOTFILES_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
		dotfiles_revision="$(git -C "$DOTFILES_DIR" rev-parse HEAD)"
	else
		dotfiles_revision="source-tree:$(file_sha256 "$ASSETS/wrappers/minuet-anthropic")"
	fi
	tmp="$(mktemp "$BINDING_DIR/.minuet-anthropic.json.XXXXXX")"
	sed \
		-e "s|@DOTFILES_REVISION@|$(sed_replacement "$dotfiles_revision")|g" \
		-e "s|@CLIENT_PATH@|$(sed_replacement "$MINUET_CLIENT")|g" \
		-e "s|@CLIENT_SHA256@|$(file_sha256 "$MINUET_CLIENT")|g" \
		-e "s|@UID@|$uid|g" \
		"$ASSETS/bindings/minuet-anthropic.json" >"$tmp"
	chmod 0600 "$tmp"
	/usr/bin/python3 -m json.tool "$tmp" >/dev/null || { rm -f "$tmp"; return 1; }
	mv "$tmp" "$MINUET_BINDING"
}

# 1. Build credproxy + credproxyd from the sibling repo. A fresh host obtains a
#    shallow working tree; an existing but incomplete path is never overwritten.
if [ ! -e "$CREDPROXY_SRC" ] && [ ! -L "$CREDPROXY_SRC" ]; then
	if ! has_cmd git; then
		log "credproxy: source unavailable (git is required for shallow fetch)"
		exit 2
	fi
	clone_root="$(mktemp -d "$(dirname "$CREDPROXY_SRC")/.credproxy.clone.XXXXXX")"
	clone_source="$clone_root/source"
	cleanup_clone() {
		rm -rf -- "$clone_root"
	}
	trap cleanup_clone EXIT HUP INT TERM
	mkdir "$clone_source"
	git -C "$clone_source" init --quiet
	git -C "$clone_source" remote add origin "$CREDPROXY_REPOSITORY"
	log "credproxy: shallow fetching pinned source -> $CREDPROXY_SRC"
	if ! git -C "$clone_source" fetch --depth 1 --filter=blob:none origin \
		"$CREDPROXY_BOOTSTRAP_REVISION"; then
		log "credproxy: source unavailable (shallow fetch failed)"
		exit 2
	fi
	observed_revision="$(git -C "$clone_source" rev-parse FETCH_HEAD 2>/dev/null || true)"
	if [ "$observed_revision" != "$CREDPROXY_BOOTSTRAP_REVISION" ]; then
		log "credproxy: conflicting (remote source revision is not the reviewed bootstrap revision)"
		exit 2
	fi
	git -c core.hooksPath=/dev/null -C "$clone_source" checkout --detach \
		"$CREDPROXY_BOOTSTRAP_REVISION" >/dev/null
	if [ -e "$CREDPROXY_SRC" ] || [ -L "$CREDPROXY_SRC" ]; then
		log "credproxy: conflicting (source path appeared during shallow fetch)"
		exit 2
	fi
	mv -- "$clone_source" "$CREDPROXY_SRC"
	rmdir "$clone_root"
	trap - EXIT HUP INT TERM
fi
if [ ! -d "$CREDPROXY_SRC/.git" ] || [ ! -d "$CREDPROXY_SRC/cmd/credproxyd" ] \
	|| [ ! -d "$CREDPROXY_SRC/cmd/credproxy" ]; then
	log "credproxy: conflicting (source repository incomplete at $CREDPROXY_SRC)"
	exit 2
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
#    reach). Existing config is accepted only with exact managed provenance or
#    the one explicitly known legacy checksum.
mkdir -p "$CONFIG_DIR"
for directory in "$RUNTIME_ROOT" "$BIN_DIR" "$HOOK_DIR" "$BINDING_DIR"; do
	if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
		log "credproxy: conflicting (trusted runtime directory identity invalid): $directory"
		exit 2
	fi
	mkdir -p "$directory"
done
chmod 0700 "$RUNTIME_ROOT" "$BIN_DIR" "$HOOK_DIR" "$BINDING_DIR"
install -m 0755 "$ASSETS/hooks/op-resolve.py" "$HOOK_DIR/op-resolve.py"
install_managed_config
install_minuet_binding_manifest
log "credproxy: hooks/wrappers refreshed"

log "credproxy: install done (secure authority 未準備なら daemon は inert)"
