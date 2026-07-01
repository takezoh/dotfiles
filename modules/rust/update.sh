#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/rust/env.sh"

has_cmd rustup || { log "rust: skip update (rustup not installed)"; exit 0; }

# devcontainer (Docker BuildKit) の overlayfs は lower layer 上のディレクトリを
# rename(2) できず (redirect_dir=off)、rustup のコンポーネント差し替えが
# EXDEV で失敗する。イメージ内 rustc は install 時点のバージョンで固定する。
if [ "${DEVCONTAINER:-}" = 1 ]; then
	log "rust: skip update (devcontainer: overlayfs rename limitation)"
	exit 0
fi

log "rust: update"
rustup update
