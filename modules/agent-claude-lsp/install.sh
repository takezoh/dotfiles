#!/bin/bash
# Install LSP server binaries used by Claude Code LSP plugins
#   - clangd       : C/C++       (Linux: apt module / macOS: brew llvm)
#   - pyright      : Python      (npm global)
#   - typescript-language-server : TypeScript/JavaScript (npm global)
#   - gopls        : Go          (go install)
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

log "agent-claude-lsp: install"

# clangd on macOS — Linux は apt モジュールで導入済み
if is_darwin && ! has_cmd clangd; then
	if has_cmd brew; then
		log "Installing llvm (provides clangd) via brew"
		brew install llvm
	else
		log "WARN: brew not found, skip clangd install"
	fi
fi

# Node 系 LSP — pyright と typescript-language-server
if has_cmd npm; then
	for pkg in pyright typescript-language-server typescript; do
		if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
			log "$pkg: already installed"
		else
			log "Installing $pkg (npm global)"
			npm install -g "$pkg"
		fi
	done
else
	log "WARN: npm not found, skip pyright/typescript-language-server"
fi

# gopls — Go ツール
if has_cmd go; then
	if has_cmd gopls; then
		log "gopls: already installed"
	else
		log "Installing gopls (go install)"
		go install golang.org/x/tools/gopls@latest
	fi
else
	log "WARN: go not found, skip gopls"
fi
