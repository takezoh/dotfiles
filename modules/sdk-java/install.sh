#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

VERSION="${JAVA_VERSION:-temurin-21}"

has_cmd mise || { log "sdk/java: mise not found, skip"; exit 0; }
mise use -g "java@$VERSION"
