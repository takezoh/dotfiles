#!/usr/bin/env bash
# Package the fail-closed credential authority. Linux/WSL retrieves the stored
# service-account token from 1Password once, keeps its sole local copy under the
# protected ~/.secrets boundary, and enables the daemon only after validation.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/credproxyd"
CONFIG_PATH="$CONFIG_DIR/config.toml"
CONFIG_PROVENANCE="$CONFIG_DIR/config.toml.managed.json"
RUNTIME_ROOT="$HOME/.local/lib/credproxy"
NATIVE_OP_BIN="/usr/local/bin/op"
WSL_OP_BIN="$RUNTIME_ROOT/bin/op"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
WSL_OP_PATH_DROPIN="$UNIT_DIR/credproxyd.service.d/30-wsl-op-path.conf"

readonly LEGACY_SHELL_PROFILE_SHA256="9f0195c3830d09628df2988241d901b50e0614d924313034b38ec5f72efe8a78"
readonly LEGACY_SHELL_PROFILE="$HOME/.local/config/zshrc/50_credproxy-env.zsh"

file_sha256() {
	if has_cmd sha256sum; then
		sha256sum "$1" | awk '{print $1}'
	elif has_cmd shasum; then
		shasum -a 256 "$1" | awk '{print $1}'
	else
		return 1
	fi
}

file_uid() {
	if stat -c '%u' "$1" >/dev/null 2>&1; then
		stat -c '%u' "$1"
	else
		stat -f '%u' "$1"
	fi
}

reconcile_legacy_shell_profile() {
	local observed_sha256

	if [ ! -e "$LEGACY_SHELL_PROFILE" ] && [ ! -L "$LEGACY_SHELL_PROFILE" ]; then
		log "credproxy: legacy shell env supply absent"
		return 0
	fi
	if [ ! -f "$LEGACY_SHELL_PROFILE" ] || [ -L "$LEGACY_SHELL_PROFILE" ]; then
		log "credproxy: conflicting (legacy shell profile provenance unknown); migration stopped"
		return 1
	fi
	if [ "$(file_uid "$LEGACY_SHELL_PROFILE")" != "$(id -u)" ]; then
		log "credproxy: conflicting (legacy shell profile owner mismatch); migration stopped"
		return 1
	fi
	if ! observed_sha256="$(file_sha256 "$LEGACY_SHELL_PROFILE")"; then
		log "credproxy: conflicting (legacy shell profile checksum unavailable); migration stopped"
		return 1
	fi
	if [ "$observed_sha256" != "$LEGACY_SHELL_PROFILE_SHA256" ]; then
		log "credproxy: conflicting (legacy shell profile user-modified); migration stopped"
		return 1
	fi

	rm -- "$LEGACY_SHELL_PROFILE"
	log "credproxy: removed managed legacy shell env supply"
}

managed_config_ready() {
	local template_sha installed_sha
	if [ ! -f "$CONFIG_PATH" ] || [ -L "$CONFIG_PATH" ] \
		|| [ ! -f "$CONFIG_PROVENANCE" ] || [ -L "$CONFIG_PROVENANCE" ]; then
		log "credproxy: conflicting (managed config/provenance absent or invalid); daemon remains disabled"
		return 1
	fi
	template_sha="$(file_sha256 "$ASSETS/config.toml")" || return 1
	installed_sha="$(file_sha256 "$CONFIG_PATH")" || return 1
	if ! /usr/bin/python3 - "$CONFIG_PROVENANCE" "$template_sha" "$installed_sha" <<'PY'
import json, sys
path, template_sha, installed_sha = sys.argv[1:]
try:
    with open(path, encoding="utf-8") as stream:
        value = json.load(stream)
except (OSError, UnicodeError, json.JSONDecodeError):
    raise SystemExit(1)
expected = {
    "schema": "credproxy-managed-config/v1",
    "owner": "dotfiles:modules/credproxy",
    "installed_revision": f"sha256:{installed_sha}",
    "template_revision": f"sha256:{template_sha}",
}
raise SystemExit(any(value.get(key) != item for key, item in expected.items()) or value.get("source_revision") != f"sha256:{installed_sha}")
PY
	then
		log "credproxy: conflicting (managed config provenance/revision mismatch); daemon remains disabled"
		return 1
	fi
}

credential_material_absent() {
	local candidate label conflicting=0
	while IFS='|' read -r label candidate; do
		[ -n "$label" ] || continue
		if [ -e "$candidate" ] || [ -L "$candidate" ]; then
			log "credproxy: conflicting (persistent credential material present: $label); daemon remains disabled"
			conflicting=1
		fi
	done <<EOF
resolved-store|$HOME/.secrets/credproxyd/resolved.json
broker-token|$CONFIG_DIR/token
grok-env-copy|$HOME/.secrets/env/skills-grok-x-search-scripts
grok-env|$HOME/.grok/.env
grok-config-env|$HOME/.config/grok/.env
grok-secret-env|$HOME/.secrets/grok.env
anthropic-key|$HOME/.secrets/anthropic_key
EOF
	for candidate in "$HOME/.codex/plugins/cache" "$HOME/.claude/plugins/cache"; do
		if [ -d "$candidate" ] && find "$candidate" -path '*/skills/grok-x-search/scripts/.env' -print -quit | grep -q .; then
			log "credproxy: conflicting (persistent credential material present: grok-script-env); daemon remains disabled"
			conflicting=1
		fi
	done
	return "$conflicting"
}

trusted_runtime_ready() {
	local path
	for path in "$RUNTIME_ROOT/bin/credproxyd" "$RUNTIME_ROOT/bin/credproxy" \
		"$RUNTIME_ROOT/hooks/op-resolve.py"; do
		if [ ! -f "$path" ] || [ -L "$path" ]; then
			log "credproxy: conflicting (trusted runtime identity unavailable); daemon remains disabled"
			return 1
		fi
	done
}

resolve_windows_op_dir() {
	local candidate
	candidate="$(command -v op.exe 2>/dev/null || true)"
	[ -n "$candidate" ] || return 1
	candidate="$(/usr/bin/realpath "$candidate" 2>/dev/null || true)"
	case "$candidate" in
		/mnt/?/Users/*/AppData/Local/Microsoft/WinGet/Packages/AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe/op.exe) ;;
		*) return 1 ;;
	esac
	[ -f "$candidate" ] && [ ! -L "$candidate" ] && [ -x "$candidate" ] || return 1
	dirname "$candidate"
}

wsl_op_ready() {
	if ! is_wsl; then
		return 0
	fi
	if [ ! -f "$WSL_OP_BIN" ] || [ -L "$WSL_OP_BIN" ] || [ ! -x "$WSL_OP_BIN" ] \
		|| [ "$(file_uid "$WSL_OP_BIN")" != "$(id -u)" ]; then
		log "credproxy: credential_source_unavailable (trusted WSL op wrapper unavailable); daemon remains disabled"
		return 1
	fi
	if ! resolve_windows_op_dir >/dev/null; then
		log "credproxy: credential_source_unavailable (Windows op.exe unavailable on PATH); daemon remains disabled"
		return 1
	fi
}

native_linux_op_ready() {
	if ! is_linux || is_wsl; then
		return 0
	fi
	if [ ! -f "$NATIVE_OP_BIN" ] || [ -L "$NATIVE_OP_BIN" ] \
		|| [ ! -x "$NATIVE_OP_BIN" ]; then
		log "credproxy: credential_source_unavailable (native 1Password CLI unavailable: $NATIVE_OP_BIN); daemon remains disabled"
		return 1
	fi
	if [ "$(file_uid "$NATIVE_OP_BIN")" != "0" ]; then
		log "credproxy: conflicting (native 1Password CLI owner is not root: $NATIVE_OP_BIN); daemon remains disabled"
		return 1
	fi
}

configure_wsl_op_path() {
	local op_dir tmp
	if ! is_wsl; then
		rm -f "$WSL_OP_PATH_DROPIN"
		return 0
	fi
	op_dir="$(resolve_windows_op_dir)" || return 1
	tmp="$(mktemp "$UNIT_DIR/credproxyd.service.d/.30-wsl-op-path.conf.XXXXXX")"
	printf '[Service]\nEnvironment="PATH=%s:%s:/usr/bin:/bin"\n' \
		"$RUNTIME_ROOT/bin" "$op_dir" >"$tmp"
	chmod 0600 "$tmp"
	mv "$tmp" "$WSL_OP_PATH_DROPIN"
}

context_service_ready() {
	if ! has_cmd curl; then
		log "credproxy: cutover pending (curl unavailable for Context Fabric health check); legacy shell profile preserved"
		return 1
	fi
	local attempt
	for attempt in 1 2 3 4 5 6 7 8 9 10; do
		if curl --fail --silent --max-time 2 http://127.0.0.1:8480/v1/healthz >/dev/null; then
			return 0
		fi
		sleep 0.2
	done
	log "credproxy: cutover pending (Context Fabric sync service unavailable); legacy shell profile preserved"
	return 1
}

if is_darwin; then
	if ! managed_config_ready || ! credential_material_absent || ! trusted_runtime_ready \
		|| ! wsl_op_ready || ! native_linux_op_ready || ! context_service_ready; then
		launchctl bootout "gui/$(id -u)/com.takezoh.credproxyd" >/dev/null 2>&1 || true
		exit 2
	fi
	PLIST_DIR="$HOME/Library/LaunchAgents"
	RUNTIME_DIR="$HOME/Library/Caches/credproxyd/runtime"
	mkdir -p "$PLIST_DIR" "$RUNTIME_DIR/credproxyd"
	tmp="$(mktemp "$PLIST_DIR/.credproxyd.plist.XXXXXX")"
	sed -e "s|@HOME@|$HOME|g" -e "s|@RUNTIME_DIR@|$RUNTIME_DIR|g" \
		"$ASSETS/launchd/credproxyd.plist" >"$tmp"
	chmod 0600 "$tmp"
	mv "$tmp" "$PLIST_DIR/com.takezoh.credproxyd.plist"
	if /usr/bin/security find-generic-password \
		-s com.takezoh.credproxy.op-service-account -a credproxyd >/dev/null 2>&1; then
		reconcile_legacy_shell_profile || exit 2
		launchctl bootout "gui/$(id -u)/com.takezoh.credproxyd" >/dev/null 2>&1 || true
		launchctl bootstrap "gui/$(id -u)" "$PLIST_DIR/com.takezoh.credproxyd.plist"
		log "credproxy: launchd enabled with fixed Keychain authority"
	else
		launchctl bootout "gui/$(id -u)/com.takezoh.credproxyd" >/dev/null 2>&1 || true
		log "credproxy: credential_source_unavailable (fixed Keychain item absent); route disabled"
	fi
	exit 0
fi

if ! has_cmd systemctl || [ ! -d /run/systemd/system ]; then
	if has_cmd systemctl; then
		systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	fi
	log "credproxy: credential_source_unavailable (systemd user service unavailable); route disabled"
	exit 0
fi

if ! managed_config_ready || ! credential_material_absent || ! trusted_runtime_ready \
	|| ! wsl_op_ready || ! native_linux_op_ready || ! context_service_ready; then
	systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	exit 2
fi

mkdir -p "$UNIT_DIR/credproxyd.service.d"
cp "$ASSETS/systemd/user/credproxyd.service" "$UNIT_DIR/credproxyd.service"
cp "$ASSETS/systemd/user/credproxyd.service.d/20-credential-source.conf" \
	"$UNIT_DIR/credproxyd.service.d/20-credential-source.conf"
if ! configure_wsl_op_path; then
	log "credproxy: credential_source_unavailable (failed to configure WSL op PATH); route disabled"
	exit 2
fi
systemctl --user daemon-reload
if bash "$MODULE_DIR/provision-service-account-token.sh"; then
	:
else
	provision_status=$?
	systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	if [ "$provision_status" -eq 2 ]; then
		exit 2
	fi
	if [ "$provision_status" -eq 3 ]; then
		exit 0
	fi
	log "credproxy: conflicting (service-account token provisioner failed unexpectedly); route disabled"
	exit 2
fi
reconcile_legacy_shell_profile || exit 2
systemctl --user enable credproxyd.service
systemctl --user restart credproxyd.service
log "credproxy: protected service-account token authority enabled"
