#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

VERSION="${GO_VERSION:-1.26.1}"

has_cmd mise || { log "sdk/go: mise not found, skip"; exit 0; }
mise use -g "go@$VERSION" 2>/dev/null || mise use -g go@latest
