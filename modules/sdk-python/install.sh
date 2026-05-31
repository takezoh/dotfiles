#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

VERSION="${PYTHON_VERSION:-3.13}"

has_cmd mise || { log "sdk/python: mise not found, skip"; exit 0; }
mise use -g "python@$VERSION"
