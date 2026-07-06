#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

GCLOUD_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/google-cloud-sdk"
GCLOUD_BIN="$GCLOUD_ROOT/bin/gcloud"
LOCAL_BIN="$HOME/.local/bin/gcloud"

if [ ! -x "$GCLOUD_BIN" ]; then
	log "cli-gcloud: skip setup (missing $GCLOUD_BIN)"
	exit 0
fi

mkdir -p "$HOME/.local/bin"
ln -snf "$GCLOUD_BIN" "$LOCAL_BIN"
log "cli-gcloud: linked $LOCAL_BIN -> $GCLOUD_BIN"
