#!/usr/bin/env bash
# installed copy を更新し、既に active な service だけを再起動する。
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$(cd "$MODULE_DIR/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

was_active=false
if is_darwin; then
	if launchctl print "gui/$(id -u)/com.takezoh.context-service" >/dev/null 2>&1; then
		was_active=true
	fi
elif has_cmd systemctl && systemctl --user is-active --quiet context-service.service; then
	was_active=true
fi
"$MODULE_DIR/install.sh"
if [ "$was_active" = true ]; then
	if is_darwin; then
		launchctl kickstart -k "gui/$(id -u)/com.takezoh.context-service"
	else
		systemctl --user restart context-service.service
	fi
fi
