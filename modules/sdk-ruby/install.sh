#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

VERSION="${RUBY_VERSION:-3.4}"

has_cmd mise || { log "sdk/ruby: mise not found, skip"; exit 0; }
mise settings ruby.compile=false
mise use -g "ruby@$VERSION"
