#!/usr/bin/env bash
# Android リバースエンジニアリング系ツール（host のみ）
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"

log "android-re: install"

brew_install \
	apktool \
	jadx \
	dex2jar \
	ta-lib
