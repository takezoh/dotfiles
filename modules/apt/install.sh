#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

APT_PACKAGES=(
	curl
	zsh
	git
	lv
	build-essential
	zlib1g-dev
	libffi-dev
	libssl-dev
	libclang-dev
	g++-i686-linux-gnu
	g++-arm-linux-gnueabi
	g++-x86-64-linux-gnux32
	g++-mingw-w64
	clangd
)

if ! is_linux; then
	log "apt: skip (not linux)"
	exit 0
fi

if [ "$(id -u)" = "0" ]; then
	as_root() { "$@"; }
else
	as_root() { sudo "$@"; }
fi

export DEBIAN_FRONTEND=noninteractive

as_root apt-get update -q
as_root apt-get install -y "${APT_PACKAGES[@]}"
