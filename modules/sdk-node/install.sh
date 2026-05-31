#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

VERSION="${NODE_VERSION:-lts}"

has_cmd mise || { log "sdk/node: mise not found, skip"; exit 0; }
mise use -g "node@$VERSION"
mise install   # バイナリを確実にインストール
mise reshim    # shims を確実に生成
