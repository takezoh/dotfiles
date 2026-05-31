#!/usr/bin/env bash
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"

log "cli: install"

# 旧 host-wsl profile から brew_install されていたパッケージ群
brew_install \
	git \
	tig \
	jq \
	yq \
	gh \
	pandoc \
	awscli \
	yarn \
	direnv \
	tree \
	wget \
	cmake \
	nkf \
	source-highlight \
	global \
	zip
