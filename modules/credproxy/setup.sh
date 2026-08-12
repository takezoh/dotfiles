#!/usr/bin/env bash
# Package the fail-closed credential authority.  This phase never reads,
# creates, copies, or rotates credential material.
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/credproxyd"
CONFIG_PATH="$CONFIG_DIR/config.toml"
CONFIG_PROVENANCE="$CONFIG_DIR/config.toml.managed.json"
RUNTIME_ROOT="$HOME/.local/lib/credproxy"

# D3 was admitted by agent-module revision 59fcde2 before squash landing.
# The immutable D2 evidence object below remains addressable; the checksum is the exact shell
# profile installed by D2; it is deliberately not derived from a live source
# asset because the source is removed in this revision.
readonly PRE_REMOVAL_ADMISSION_REVISION="59fcde2"
readonly CONTEXT_FABRIC_ADMISSION_REVISION="23b827bb3eb68b6eb16adbbeeeb8879680dd04f9"
readonly CONTEXT_FABRIC_HOOK_SHA256="3b690a4a52def2572d4b2128397339c147698cfab7a215a3ab80dc4d3e62ac15"
readonly DOTFILES_D2_EVIDENCE_REVISION="f46bface982ff475dceca7926d8f5ce1dd2e029f"
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
service-account-token|$HOME/.secrets/op/service-account.token
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
		"$RUNTIME_ROOT/bin/ctx-sync" "$RUNTIME_ROOT/bindings/ctx-sync.json" \
		"$RUNTIME_ROOT/hooks/op-resolve.py"; do
		if [ ! -f "$path" ] || [ -L "$path" ]; then
			log "credproxy: conflicting (trusted runtime identity unavailable); daemon remains disabled"
			return 1
		fi
	done
}

consumer_admission_ready() {
	local handshake expected hook hook_count=0
	if [ ! -x "$RUNTIME_ROOT/bin/ctx" ]; then
		log "credproxy: cutover pending (fixed operation ctx unavailable); legacy shell profile preserved"
		return 1
	fi
	if ! "$RUNTIME_ROOT/bin/ctx" version 2>/dev/null | grep -Fq "build      $CONTEXT_FABRIC_ADMISSION_REVISION clean"; then
		log "credproxy: cutover pending (fixed operation ctx revision mismatch); legacy shell profile preserved"
		return 1
	fi
	expected="$(/usr/bin/python3 - "$RUNTIME_ROOT/bindings/ctx-sync.json" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        value = json.load(stream)
    print(value["schema"], value["binding_revision"], value["producer_revision"])
except (OSError, KeyError, TypeError, UnicodeError, json.JSONDecodeError):
    raise SystemExit(1)
PY
)" || return 1
	handshake="$("$RUNTIME_ROOT/bin/ctx-sync" --credroute-version 2>/dev/null)" || return 1
	if [ "$expected" != "$handshake" ]; then
		log "credproxy: cutover pending (ctx binding handshake mismatch); legacy shell profile preserved"
		return 1
	fi
	for hook in \
		"$HOME/.codex/plugins/cache/context-fabric/context-fabric/0.1.0/hooks/session-start.sh" \
		"$HOME/.claude/plugins/cache/context-fabric/context-fabric/0.1.0/hooks/session-start.sh"; do
		[ -e "$hook" ] || continue
		hook_count=$((hook_count + 1))
		if [ ! -f "$hook" ] || [ -L "$hook" ] \
			|| [ "$(file_sha256 "$hook")" != "$CONTEXT_FABRIC_HOOK_SHA256" ]; then
			log "credproxy: cutover pending (active ctx hook identity mismatch); legacy shell profile preserved"
			return 1
		fi
	done
	if [ "$hook_count" -eq 0 ]; then
		log "credproxy: cutover pending (active ctx hook unavailable); legacy shell profile preserved"
		return 1
	fi
}

if is_darwin; then
	if ! managed_config_ready || ! credential_material_absent || ! trusted_runtime_ready || ! consumer_admission_ready; then
		launchctl bootout "gui/$(id -u)/com.takezoh.credproxyd" >/dev/null 2>&1 || true
		exit 2
	fi
	PLIST_DIR="$HOME/Library/LaunchAgents"
	RUNTIME_DIR="$HOME/Library/Caches/credproxyd/runtime"
	mkdir -p "$PLIST_DIR" "$RUNTIME_DIR"
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

if ! has_cmd systemctl || [ ! -d /run/systemd/system ] || ! systemd-creds --help >/dev/null 2>&1; then
	if has_cmd systemctl; then
		systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	fi
	log "credproxy: credential_source_unavailable (systemd encrypted credentials unsupported); route disabled"
	exit 0
fi

if ! managed_config_ready || ! credential_material_absent || ! trusted_runtime_ready || ! consumer_admission_ready; then
	systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	exit 2
fi

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
ENCRYPTED="$CONFIG_DIR/credentials/op-service-account.cred"
mkdir -p "$UNIT_DIR/credproxyd.service.d"
cp "$ASSETS/systemd/user/credproxyd.service" "$UNIT_DIR/credproxyd.service"
cp "$ASSETS/systemd/user/credproxyd.service.d/20-credential-source.conf" \
	"$UNIT_DIR/credproxyd.service.d/20-credential-source.conf"
systemctl --user daemon-reload
if [ ! -f "$ENCRYPTED" ]; then
	systemctl --user disable --now credproxyd.service >/dev/null 2>&1 || true
	log "credproxy: credential_source_unavailable (encrypted credential absent); route disabled"
	exit 0
fi
reconcile_legacy_shell_profile || exit 2
systemctl --user enable credproxyd.service
systemctl --user restart credproxyd.service
log "credproxy: systemd encrypted credential authority enabled"
