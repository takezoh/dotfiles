#!/usr/bin/env bash
# Context Fabric product binary を trusted runtime へ atomic install する。
# product config、principal、credential、sync semantics はこの module では扱わない。
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

CONTEXT_FABRIC_SRC="$(cd "$DOTFILES_DIR/.." && pwd -P)/context-fabric"
RUNTIME_ROOT="$HOME/.local/lib/context-fabric"
BIN_DIR="$RUNTIME_ROOT/bin"
TARGET="$BIN_DIR/context-service"

if [ ! -d "$CONTEXT_FABRIC_SRC" ]; then
	log "context-fabric-service: source_unavailable ($CONTEXT_FABRIC_SRC)"
	exit 2
fi
if ! has_cmd go; then
	log "context-fabric-service: runtime_unavailable (go)"
	exit 2
fi
for directory in "$RUNTIME_ROOT" "$BIN_DIR"; do
	if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
		log "context-fabric-service: conflicting (trusted runtime directory identity invalid): $directory"
		exit 2
	fi
	mkdir -p "$directory"
done
chmod 0700 "$RUNTIME_ROOT" "$BIN_DIR"

tmp="$(mktemp "$BIN_DIR/.context-service.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
log "context-fabric-service: building installed copy"
( cd "$CONTEXT_FABRIC_SRC" && go build -o "$tmp" ./cmd/context-service )
chmod 0700 "$tmp"
mv "$tmp" "$TARGET"
trap - EXIT
log "context-fabric-service: installed $TARGET"
