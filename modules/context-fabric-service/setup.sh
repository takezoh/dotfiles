#!/usr/bin/env bash
# Product-owned config を消費し、OS service lifecycle だけを構成する。
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

ASSETS="$(cd "$(dirname "$0")" && pwd)/assets"
BINARY="$HOME/.local/lib/context-fabric/bin/context-service"
CTX="$HOME/.local/bin/ctx"
CLIENT_CONFIG="$HOME/.local/lib/context-fabric/client/.ctx/config.json"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/context-fabric/service.json"
STATE_DIR="$HOME/.local/state/context-fabric"
SNAPSHOT="$HOME/.cache/context-fabric/personal/remote-snapshot.json"
PRINCIPALS="$STATE_DIR/principals.jsonl"
DEPLOYMENT_TENANT="personal"
. "$MODULES_DIR/credproxy/socket-path.sh"
BROKER_SOCKET="$(broker_socket_path)"

disable_service() {
	if is_darwin; then
		launchctl bootout "gui/$(id -u)/com.takezoh.context-service" >/dev/null 2>&1 || true
	elif has_cmd systemctl; then
		systemctl --user disable --now context-service.service >/dev/null 2>&1 || true
	fi
}

if [ ! -x "$BINARY" ] || [ -L "$BINARY" ]; then
	disable_service
	log "context-fabric-service: runtime_unavailable (run install first)"
	exit 2
fi
if [ ! -x "$CTX" ] || [ -L "$CTX" ]; then
	disable_service
	log "context-fabric-service: client_cli_unavailable ($CTX); agent-module setupを実行する"
	exit 2
fi
if [ ! -f "$CLIENT_CONFIG" ] || [ -L "$CLIENT_CONFIG" ]; then
	disable_service
	log "context-fabric-service: client_config_unavailable ($CLIENT_CONFIG); agent-module setupを実行する"
	exit 2
fi

mkdir -p "$STATE_DIR" "$(dirname "$SNAPSHOT")" "$(dirname "$CONFIG")"
if ! "$CTX" service init \
	-config "$CLIENT_CONFIG" \
	-tenant "$DEPLOYMENT_TENANT" \
	-service-config "$CONFIG" \
	-state-dir "$STATE_DIR" \
	-snapshot-path "$SNAPSHOT" \
	-principals-path "$PRINCIPALS" \
	-sync-proxy-socket "$BROKER_SOCKET"; then
	disable_service
	log "context-fabric-service: service_init_failed"
	exit 2
fi
if [ ! -f "$CONFIG" ] || [ -L "$CONFIG" ]; then
	disable_service
	log "context-fabric-service: service_config_unavailable ($CONFIG)"
	exit 2
fi

if is_darwin; then
	plist_dir="$HOME/Library/LaunchAgents"
	mkdir -p "$plist_dir" "$HOME/Library/Logs"
	tmp="$(mktemp "$plist_dir/.context-service.plist.XXXXXX")"
	sed -e "s|@HOME@|$HOME|g" "$ASSETS/launchd/context-service.plist" >"$tmp"
	chmod 0600 "$tmp"
	mv "$tmp" "$plist_dir/com.takezoh.context-service.plist"
	launchctl bootout "gui/$(id -u)/com.takezoh.context-service" >/dev/null 2>&1 || true
	launchctl bootstrap "gui/$(id -u)" "$plist_dir/com.takezoh.context-service.plist"
else
	if ! has_cmd systemctl || [ ! -d /run/systemd/system ]; then
		disable_service
		log "context-fabric-service: service_manager_unavailable"
		exit 2
	fi
	unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
	mkdir -p "$unit_dir"
	cp "$ASSETS/systemd/user/context-service.service" "$unit_dir/context-service.service"
	systemctl --user daemon-reload
	systemctl --user enable context-service.service >/dev/null
	systemctl --user restart context-service.service
fi

if ! has_cmd curl; then
	disable_service
	log "context-fabric-service: health_probe_unavailable (curl)"
	exit 2
fi
for attempt in 1 2 3 4 5 6 7 8 9 10; do
	if curl --fail --silent --max-time 2 http://127.0.0.1:8480/v1/healthz >/dev/null; then
		log "context-fabric-service: service healthy"
		exit 0
	fi
	sleep 0.2
done
disable_service
log "context-fabric-service: service_unavailable (GET /v1/healthz)"
exit 2
